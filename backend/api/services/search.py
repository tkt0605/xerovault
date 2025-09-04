from typing import Iterable, Literal, Tuple, List, Dict
from django.db.models import Q, QuerySet, Value, CharField, F, FloatField
from django.utils.timezone import now
# from django.contrib.postgres.search import SearchQuery, SearchVector, SearchRank
# from django.contrib.postgres.search import TrigramSimilarity
# from django.db.models.functions import Cast, Coalesce
# from typing import TYPE_CHECKING
# if TYPE_CHECKING:
#     from api.models import GenerateGroup, GenerateLibrary
from api.models import GenerateGroup, GenerateLibrary
SearchMode = Literal['basic', 'fuzzy', 'fts']


class GlobalSearchEngine:
    def __init__(self, q: str, mode: SearchMode = 'basic', fuzzy_threshold: float = 0.2, request=None):
        self.q = (q or '').strip()
        self.mode = mode
        self.fuzzy_threshold = fuzzy_threshold
        self.request = request

    # ===== public =====
    def run(self) -> Tuple[QuerySet, QuerySet]:
        user = self.request.user
        qs_g = GenerateGroup.objects.filter(
            Q(owner=user)|Q(members=user)
            )
        qs_l = GenerateLibrary.objects.filter(
            owner=user
        )
        """グループとライブラリの2系統の検索結果（values() の dict クエリセット）を返す"""
        group_qs = qs_g.filter(name__icontains=self.q).annotate(
            search_score=Value(1.0, output_field=FloatField())
        ).values("id", "name", "created_at", "search_score")

        library_qs = qs_l.filter(name__icontains=self.q).annotate(
            search_score=Value(1.0, output_field=FloatField())
        ).values("id", "name", "created_at", "search_score")

        return group_qs, library_qs
        # if not self.q:
        #     from api.models import GenerateGroup, GenerateLibrary
        #     return (
        #         GenerateGroup.objects.none().values('id', 'created_at'),
        #         GenerateLibrary.objects.none().values('id', 'created_at'),
        #     )

        # if self.mode == 'basic':
        #     return self._basic_group(), self._basic_library()
        # elif self.mode == 'fuzzy':
        #     return self._fuzzy_group(), self._fuzzy_library()
        # elif self.mode == 'fts':
        #     return self._fts_group(), self._fts_library()
        # else:
        #     # 不明モードは basic
        #     return self._basic_group(), self._basic_library()

    def combined(self, limit: int | None = None, offset: int = 0) -> List[Dict]:
        g_qs, l_qs = self.run()
        # スコア付け & ソート処理（任意）
        def process(rows):
            for i in rows:
                if 'search_score' in i:
                    i['score'] = i.pop('search_score')
            return sorted(rows, key=lambda i: (i.get('score') or 0.0, i.get('created_at') or now()), reverse=True)

        groups = process(list(g_qs))
        libraries = process(list(l_qs))

        if offset or limit is not None:
            end = None if limit is None else offset + limit
            groups = groups[offset:end]
            libraries = libraries[offset:end]

        return {
            "groups": groups,
            "libraries": libraries,
        }
    # # ===== bases (values+annotate 共通化) =====
    # def _decorate_group_values(self, qs) -> QuerySet:
    #     return (
    #         qs
    #         # 既存の IntField `score` を Float にキャストして search_score に
    #         .annotate(search_score=Cast(Coalesce(F('score'), Value(0)), FloatField()))
    #         .order_by('-search_score')
    #         .values(
    #             'id',
    #             'name',
    #             'tag',
    #             'is_public',
    #             'created_at',
    #             'updated_at',
    #             'search_score',   # レスポンスキーは score のまま出す
    #         )
    #         .distinct()  # M2M 結合で重複が出る保険
    #     )


    # def _decorate_library_values(self, qs) -> QuerySet:
    #     return (
    #         qs
    #         # Library には score フィールドが無いので、計算 or デフォルト値
    #         .annotate(search_score=Value(0.0, output_field=FloatField()))
    #         .order_by('-search_score')
    #         .values(
    #             'id',
    #             'name',
    #             'tag',
    #             'is_public',
    #             'created_at',
    #             'updated_at',
    #             'search_score'
    #         )
    #         .distinct()
    #     )

    # # ===== basic =====
    # def _basic_group(self) -> QuerySet:
    #     from api.models import GenerateGroup
    #     qs = GenerateGroup.objects.filter(
    #         Q(name__icontains=self.q) | Q(tag__icontains=self.q)
    #     ).order_by('-created_at')
    #     return self._decorate_group_values(qs)

    # def _basic_library(self) -> QuerySet:
    #     from api.models import GenerateLibrary
    #     qs = GenerateLibrary.objects.filter(
    #         Q(name__icontains=self.q) | Q(tag__icontains=self.q)
    #     ).order_by('-created_at')
    #     return self._decorate_library_values(qs)

    # # ===== fuzzy (pg_trgm) =====
    # def _fuzzy_group(self) -> QuerySet:
    #     from api.models import GenerateGroup
    #     qs = GenerateGroup.objects.annotate(
    #         s1=TrigramSimilarity('name', self.q),
    #         s2=TrigramSimilarity('tag', self.q),
    #     ).filter(
    #         Q(s1__gt=self.fuzzy_threshold) | Q(s2__gt=self.fuzzy_threshold)
    #     ).annotate(
    #         score=F('s1') + F('s2')
    #     ).order_by('-score', '-created_at')

    #     # 注釈済み score を values に含める
    #     qs = qs.values('id', 'created_at').annotate(
    #         kind=Value('studio', output_field=CharField()),
    #         title=F('name'),
    #         description=F('tag'),
    #         score=F('score'),
    #     )
    #     return qs.order_by('-score', '-created_at')

    # def _fuzzy_library(self) -> QuerySet:
    #     from api.models import GenerateLibrary
    #     qs = GenerateLibrary.objects.annotate(
    #         s1=TrigramSimilarity('name', self.q),
    #         s2=TrigramSimilarity('tag', self.q),
    #     ).filter(
    #         Q(s1__gt=self.fuzzy_threshold) | Q(s2__gt=self.fuzzy_threshold)
    #     ).annotate(
    #         score=F('s1') + F('s2')
    #     ).order_by('-score', '-created_at')

    #     qs = qs.values('id', 'created_at').annotate(
    #         kind=Value('library', output_field=CharField()),
    #         title=F('name'),
    #         description=F('tag'),
    #         score=F('score'),
    #     )
    #     return qs.order_by('-score', '-created_at')

    # # ===== FTS =====
    # def _fts_group(self) -> QuerySet:
    #     from api.models import GenerateGroup
    #     vector = SearchVector('name', weight='A') + SearchVector('tag', weight='B')
    #     query = SearchQuery(self.q)
    #     base = GenerateGroup.objects.annotate(rank=SearchRank(vector, query)).filter(rank__gte=0.05)

    #     qs = base.values('id', 'created_at').annotate(
    #         kind=Value('studio', output_field=CharField()),
    #         title=F('name'),
    #         description=F('tag'),
    #         score=F('rank'),
    #     )
    #     return qs.order_by('-score', '-created_at')

    # def _fts_library(self) -> QuerySet:
    #     from api.models import GenerateLibrary
    #     vector = SearchVector('name', weight='A') + SearchVector('tag', weight='B')
    #     query = SearchQuery(self.q)   # ← 修正
    #     base = GenerateLibrary.objects.annotate(rank=SearchRank(vector, query)).filter(rank__gte=0.05)

    #     qs = base.values('id', 'created_at').annotate(
    #         kind=Value('library', output_field=CharField()),
    #         title=F('name'),
    #         description=F('tag'),
    #         score=F('rank'),
    #     )
    #     return qs.order_by('-score', '-created_at')
