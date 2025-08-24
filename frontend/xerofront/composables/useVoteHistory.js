// composables/useVoteHistory.js

const isClient = () => typeof window !== "undefined";

function getStorageKey(userId) {
  return `vote_history_${userId}_v1`;
}

// 履歴全体をロード
export function loadVote(userId) {
  if (!isClient()) return {};
  const key = getStorageKey(userId);
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : {};
  } catch (error) {
    console.error('投票トークンの読み込み失敗：', error);
    return {};
  }
}

// 指定ゴールに対して投票済みか
export function hasVote(userId, goalId) {
  const history = loadVote(userId);
  return !!history[goalId];
}

// 投票内容を取得（true/false/null）
export function getVote(userId, goalId) {
  const history = loadVote(userId);
  return history[goalId]?.is_yes ?? null;
}

// 履歴を保存
export function setVote(userId, goalId, isYes) {
  if (!isClient() || !userId || !goalId) return;

  const key = getStorageKey(userId);
  const history = loadVote(userId);
  history[goalId] = {
    is_yes: isYes,
    ts: Date.now()
  };

  try {
    localStorage.setItem(key, JSON.stringify(history));
  } catch (e) {
    console.error('投票履歴の保存失敗:', e);
  }
}
