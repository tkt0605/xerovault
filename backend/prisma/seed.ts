import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

function avatarUrl(email: string): string {
  return `https://api.dicebear.com/9.x/identicon/svg?seed=${email.split('@')[0]}`
}

async function main() {
  const password = await bcrypt.hash('password123', 12)

  const owner = await prisma.user.upsert({
    where: { email: 'owner@example.com' },
    update: {},
    create: {
      email: 'owner@example.com',
      name: 'オーナー太郎',
      password,
      avatar: avatarUrl('owner@example.com'),
    },
  })

  const member = await prisma.user.upsert({
    where: { email: 'member@example.com' },
    update: {},
    create: {
      email: 'member@example.com',
      name: 'メンバー花子',
      password,
      avatar: avatarUrl('member@example.com'),
    },
  })

  const group = await prisma.group.upsert({
    where: { name: 'サンプルスタジオ' },
    update: {},
    create: {
      name: 'サンプルスタジオ',
      isPublic: true,
      ownerId: owner.id,
      members: { connect: [{ id: owner.id }, { id: member.id }] },
    },
  })

  const goal = await prisma.goal.create({
    data: {
      description: '毎日30分運動する',
      isConcrete: true,
      groupId: group.id,
      assigneeId: member.id,
    },
  })

  const goalVote = await prisma.goalVote.create({
    data: { goalId: goal.id, voterId: owner.id },
  })

  await prisma.vote.create({
    data: { goalVoteId: goalVote.id, voterId: owner.id, isYes: true },
  })

  await prisma.message.create({
    data: { goalId: goal.id, authorId: owner.id, text: 'よろしくお願いします!' },
  })

  console.log('Seed completed:', { owner: owner.email, member: member.email, group: group.name })
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
