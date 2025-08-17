from typing import Iterable, Literal, Tuple, List, Dict
from django.db.models import Q, QuerySet, Value, CharField, F, FloatField
from django.utils.timezone import now
from django.contrib.postgres.search import SearchQuery, SearchVector, SearchRank
from django.contrib.postgres.search import TrigramSimilarity
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from api.models import GenerateGroup, GenerateLibrary

SearchMode = Literal['basic', 'fuzzy', 'fts']


class GlobalSearchEngine:
    def __init__(self, q: str, mode: SearchMode = 'basic', fuzzy_threshold: float = 0.2):
        self.q = (q or '').strip()
        self.mode = mode
        self.fuzzy_threshold = fuzzy_threshold

    # ===== public =====
    def run(self) -> Tuple[QuerySet, QuerySet]:
        """グループとライブラリの2系統の検索結果（values() の dict クエリセット）を返す"""
        if not self.q:
            from api.models import GenerateGroup, GenerateLibrary
            return (
                GenerateGroup.objects.none().values('id', 'created_at'),
                GenerateLibrary.objects.none().values('id', 'created_at'),
            )

        if self.mode == 'basic':
            return self._basic_group(), self._basic_library()
        elif self.mode == 'fuzzy':
            return self._fuzzy_group(), self._fuzzy_library()
        elif self.mode == 'fts':
            return self._fts_group(), self._fts_library()
        else:
            # 不明モードは basic
            return self._basic_group(), self._basic_library()

    def combined(self, limit: int | None = None, offset: int = 0) -> List[Dict]:
        """二系統を結合して score, created_at で降順ソートした配列を返す"""
        g_qs, l_qs = self.run()
        rows = list(g_qs) + list(l_qs)
        rows.sort(
            key=lambda r: (r.get('score') or 0.0, r.get('created_at') or now()),
            reverse=True,
        )
        if offset or limit is not None:
            end = None if limit is None else offset + limit
            return rows[offset:end]
        return rows

    # ===== bases (values+annotate 共通化) =====
    def _decorate_group_values(self, qs) -> QuerySet:
        """GenerateGroup ベースの qs に共通注釈/values を付与"""
        qs = qs.annotate(
            kind=Value('studio', output_field=CharField()),
            title=F('name'),
            description=F('tag'),
        )
        # score が無い場合のデフォルト（0.0）
        qs = qs.annotate(score=Value(0.0, output_field=FloatField()))
        return qs.values('id', 'created_at', 'kind', 'title', 'description', 'score')

    def _decorate_library_values(self, qs) -> QuerySet:
        """GenerateLibrary ベースの qs に共通注釈/values を付与"""
        qs = qs.annotate(
            kind=Value('library', output_field=CharField()),
            title=F('name'),
            description=F('tag'),
        )
        qs = qs.annotate(score=Value(0.0, output_field=FloatField()))
        return qs.values('id', 'created_at', 'kind', 'title', 'description', 'score')

    # ===== basic =====
    def _basic_group(self) -> QuerySet:
        from api.models import GenerateGroup
        qs = GenerateGroup.objects.filter(
            Q(name__icontains=self.q) | Q(tag__icontains=self.q)
        ).order_by('-created_at')
        return self._decorate_group_values(qs)

    def _basic_library(self) -> QuerySet:
        from api.models import GenerateLibrary
        qs = GenerateLibrary.objects.filter(
            Q(name__icontains=self.q) | Q(tag__icontains=self.q)
        ).order_by('-created_at')
        return self._decorate_library_values(qs)

    # ===== fuzzy (pg_trgm) =====
    def _fuzzy_group(self) -> QuerySet:
        from api.models import GenerateGroup
        qs = GenerateGroup.objects.annotate(
            s1=TrigramSimilarity('name', self.q),
            s2=TrigramSimilarity('tag', self.q),
        ).filter(
            Q(s1__gt=self.fuzzy_threshold) | Q(s2__gt=self.fuzzy_threshold)
        ).annotate(
            score=F('s1') + F('s2')
        ).order_by('-score', '-created_at')

        # 注釈済み score を values に含める
        qs = qs.values('id', 'created_at').annotate(
            kind=Value('studio', output_field=CharField()),
            title=F('name'),
            description=F('tag'),
            score=F('score'),
        )
        return qs.order_by('-score', '-created_at')

    def _fuzzy_library(self) -> QuerySet:
        from api.models import GenerateLibrary
        qs = GenerateLibrary.objects.annotate(
            s1=TrigramSimilarity('name', self.q),
            s2=TrigramSimilarity('tag', self.q),
        ).filter(
            Q(s1__gt=self.fuzzy_threshold) | Q(s2__gt=self.fuzzy_threshold)
        ).annotate(
            score=F('s1') + F('s2')
        ).order_by('-score', '-created_at')

        qs = qs.values('id', 'created_at').annotate(
            kind=Value('library', output_field=CharField()),
            title=F('name'),
            description=F('tag'),
            score=F('score'),
        )
        return qs.order_by('-score', '-created_at')

    # ===== FTS =====
    def _fts_group(self) -> QuerySet:
        from api.models import GenerateGroup
        vector = SearchVector('name', weight='A') + SearchVector('tag', weight='B')
        query = SearchQuery(self.q)
        base = GenerateGroup.objects.annotate(rank=SearchRank(vector, query)).filter(rank__gte=0.05)

        qs = base.values('id', 'created_at').annotate(
            kind=Value('studio', output_field=CharField()),
            title=F('name'),
            description=F('tag'),
            score=F('rank'),
        )
        return qs.order_by('-score', '-created_at')

    def _fts_library(self) -> QuerySet:
        from api.models import GenerateLibrary
        vector = SearchVector('name', weight='A') + SearchVector('tag', weight='B')
        query = SearchQuery(self.q)   # ← 修正
        base = GenerateLibrary.objects.annotate(rank=SearchRank(vector, query)).filter(rank__gte=0.05)

        qs = base.values('id', 'created_at').annotate(
            kind=Value('library', output_field=CharField()),
            title=F('name'),
            description=F('tag'),
            score=F('rank'),
        )
        return qs.order_by('-score', '-created_at')
