import { describe, it, expect } from 'vitest'
import {
  calcGoalPoints,
  calcGroupScore,
  calcProgress,
  BASE_SCORE,
  CONCRETE_GOAL_PTS,
  VAGUE_GOAL_PTS,
  FULL_PARTICIPATION_BONUS,
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
    expect(calcGroupScore([], 4, 0)).toBe(BASE_SCORE)
  })

  it('達成ゴールの得点を積み上げる', () => {
    const goals = [
      { hasDeadline: true, hasAssignee: true, participantCount: 4 }, // 100% 参加ボーナス
      { hasDeadline: false, hasAssignee: false, participantCount: 1 }, // ボーナスなし
    ]
    const expected =
      BASE_SCORE + Math.round(CONCRETE_GOAL_PTS * FULL_PARTICIPATION_BONUS) + VAGUE_GOAL_PTS
    expect(calcGroupScore(goals, 4, 0)).toBe(expected)
  })

  it('streakが3以上ならSTREAK_BONUSを加算', () => {
    expect(calcGroupScore([], 4, 3)).toBe(BASE_SCORE + STREAK_BONUS)
    expect(calcGroupScore([], 4, 2)).toBe(BASE_SCORE)
  })

  it('MAX_SCOREでクランプする', () => {
    const manyGoals = Array.from({ length: 1000 }, () => ({
      hasDeadline: true,
      hasAssignee: true,
      participantCount: 4,
    }))
    expect(calcGroupScore(manyGoals, 4, 5)).toBe(MAX_SCORE)
  })
})
