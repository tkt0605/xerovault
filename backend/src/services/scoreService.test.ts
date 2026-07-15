import { describe, it, expect } from 'vitest'
import {
  calcGoalPoints,
  calcGroupScore,
  calcProgress,
  calcStreak,
  calcGoalStatus,
  BASE_SCORE,
  MIN_SCORE,
  CONCRETE_GOAL_PTS,
  VAGUE_GOAL_PTS,
  FULL_PARTICIPATION_BONUS,
  MISSED_GOAL_PENALTY,
  STREAK_BONUS,
  MAX_SCORE,
} from './scoreService'

describe('calcProgress', () => {
  it('YES票の割合を0〜100の整数で返す', () => {
    expect(calcProgress(3, 4)).toBe(75)
    expect(calcProgress(1, 3)).toBe(33)
    expect(calcProgress(2, 3)).toBe(67)
  })

  it('全員YESなら100', () => {
    expect(calcProgress(5, 5)).toBe(100)
  })

  it('誰もYESでなければ0', () => {
    expect(calcProgress(0, 5)).toBe(0)
  })

  it('メンバーが0人なら0（ゼロ除算を回避）', () => {
    expect(calcProgress(0, 0)).toBe(0)
  })
})

describe('calcGoalPoints', () => {
  it('期限・担当者ありは CONCRETE_GOAL_PTS を基礎点にする', () => {
    const pts = calcGoalPoints({ hasDeadline: true, hasAssignee: true, participantCount: 0 }, 4)
    expect(pts).toBe(CONCRETE_GOAL_PTS)
  })

  it('期限か担当者のどちらかが欠けていれば VAGUE_GOAL_PTS', () => {
    expect(calcGoalPoints({ hasDeadline: true, hasAssignee: false, participantCount: 0 }, 4)).toBe(
      VAGUE_GOAL_PTS
    )
    expect(calcGoalPoints({ hasDeadline: false, hasAssignee: true, participantCount: 0 }, 4)).toBe(
      VAGUE_GOAL_PTS
    )
    expect(calcGoalPoints({ hasDeadline: false, hasAssignee: false, participantCount: 0 }, 4)).toBe(
      VAGUE_GOAL_PTS
    )
  })

  it('投票参加率100%なら FULL_PARTICIPATION_BONUS 倍（四捨五入）', () => {
    const pts = calcGoalPoints({ hasDeadline: true, hasAssignee: true, participantCount: 4 }, 4)
    expect(pts).toBe(Math.round(CONCRETE_GOAL_PTS * FULL_PARTICIPATION_BONUS))
  })

  it('参加率が100%未満ならボーナスなし', () => {
    const pts = calcGoalPoints({ hasDeadline: true, hasAssignee: true, participantCount: 3 }, 4)
    expect(pts).toBe(CONCRETE_GOAL_PTS)
  })

  it('totalMembersが0でもゼロ除算しない', () => {
    expect(calcGoalPoints({ hasDeadline: true, hasAssignee: true, participantCount: 0 }, 0)).toBe(
      CONCRETE_GOAL_PTS
    )
  })
})

describe('calcGroupScore', () => {
  it('達成ゴールがなければ BASE_SCORE のみ', () => {
    expect(calcGroupScore([], 0, 4, 0)).toBe(BASE_SCORE)
  })

  it('達成ゴールの得点を積み上げる', () => {
    const goals = [
      { hasDeadline: true, hasAssignee: true, participantCount: 4 }, // 100% 参加ボーナス
      { hasDeadline: false, hasAssignee: false, participantCount: 1 }, // ボーナスなし
    ]
    const expected =
      BASE_SCORE + Math.round(CONCRETE_GOAL_PTS * FULL_PARTICIPATION_BONUS) + VAGUE_GOAL_PTS
    expect(calcGroupScore(goals, 0, 4, 0)).toBe(expected)
  })

  it('missed concrete goal 1件につき MISSED_GOAL_PENALTY を減点する', () => {
    expect(calcGroupScore([], 2, 4, 0)).toBe(BASE_SCORE - 2 * MISSED_GOAL_PENALTY)
  })

  it('streakが3以上ならSTREAK_BONUSを加算', () => {
    expect(calcGroupScore([], 0, 4, 3)).toBe(BASE_SCORE + STREAK_BONUS)
    expect(calcGroupScore([], 0, 4, 2)).toBe(BASE_SCORE)
  })

  it('MAX_SCOREでクランプする', () => {
    const manyGoals = Array.from({ length: 1000 }, () => ({
      hasDeadline: true,
      hasAssignee: true,
      participantCount: 4,
    }))
    expect(calcGroupScore(manyGoals, 0, 4, 5)).toBe(MAX_SCORE)
  })

  it('MIN_SCOREを下回らない（ペナルティが大きくてもマイナスにならない）', () => {
    expect(calcGroupScore([], 1000, 4, 0)).toBe(MIN_SCORE)
  })
})

describe('calcStreak', () => {
  const d = (daysAgo: number) => new Date(Date.now() - daysAgo * 86400000)

  it('resolvedなgoalがなければ0', () => {
    expect(calcStreak([])).toBe(0)
  })

  it('最新から連続で達成している件数を数える', () => {
    const goals = [
      { deadline: d(30), isCompleted: true },
      { deadline: d(20), isCompleted: true },
      { deadline: d(10), isCompleted: true },
    ]
    expect(calcStreak(goals)).toBe(3)
  })

  it('missedに当たった時点で打ち切る', () => {
    const goals = [
      { deadline: d(30), isCompleted: true },
      { deadline: d(20), isCompleted: false }, // missed
      { deadline: d(10), isCompleted: true },
      { deadline: d(5), isCompleted: true },
    ]
    expect(calcStreak(goals)).toBe(2)
  })

  it('渡す順序に依存しない（内部でdeadline昇順に並べ替える）', () => {
    const goals = [
      { deadline: d(10), isCompleted: true },
      { deadline: d(30), isCompleted: true },
      { deadline: d(20), isCompleted: false },
    ]
    expect(calcStreak(goals)).toBe(1)
  })

  it('直近がmissedなら0', () => {
    const goals = [
      { deadline: d(30), isCompleted: true },
      { deadline: d(10), isCompleted: false },
    ]
    expect(calcStreak(goals)).toBe(0)
  })
})

describe('calcGoalStatus', () => {
  const future = new Date(Date.now() + 86400000)
  const past = new Date(Date.now() - 86400000)

  it('isCompletedならcompleted', () => {
    expect(calcGoalStatus({ isCompleted: true, deadline: past, assigneeId: 'u1' })).toBe(
      'completed'
    )
  })

  it('concrete goalでdeadlineが過去かつ未達成ならmissed', () => {
    expect(calcGoalStatus({ isCompleted: false, deadline: past, assigneeId: 'u1' })).toBe('missed')
  })

  it('concrete goalでdeadlineが未来ならpending', () => {
    expect(calcGoalStatus({ isCompleted: false, deadline: future, assigneeId: 'u1' })).toBe(
      'pending'
    )
  })

  it('vague goal(assigneeなし)はdeadlineが過去でもmissedにならない', () => {
    expect(calcGoalStatus({ isCompleted: false, deadline: past, assigneeId: null })).toBe('pending')
  })

  it('vague goal(deadlineなし)はpending', () => {
    expect(calcGoalStatus({ isCompleted: false, deadline: null, assigneeId: 'u1' })).toBe('pending')
  })
})
