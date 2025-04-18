import { sql } from 'drizzle-orm'
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core'
import { mysqlTable, varchar, int, timestamp, mysqlEnum } from 'drizzle-orm/mysql-core'
import { pgTable, text as pgText, integer as pgInteger, timestamp as pgTimestamp } from 'drizzle-orm/pg-core'

type DbType = 'sqlite' | 'mysql' | 'pg' | 'd1'

const getDbType = (): DbType => {
  const dbType = process.env.DB_TYPE as DbType
  if (!dbType || !['sqlite', 'mysql', 'pg', 'd1'].includes(dbType)) {
    return 'sqlite' // Default to SQLite
  }
  return dbType
}

const createSystemConfig = () => {
  const dbType = getDbType()

  switch (dbType) {
    case 'mysql':
      return mysqlTable('system_config', {
        id: int('id').primaryKey().autoincrement(),
        key: varchar('key', { length: 255 }).notNull().unique(),
        value: varchar('value', { length: 255 }).notNull(),
        description: varchar('description', { length: 255 }),
        createdAt: timestamp('created_at').notNull().defaultNow(),
        updatedAt: timestamp('updated_at').notNull().defaultNow()
      })
    case 'pg':
      return pgTable('system_config', {
        id: pgInteger('id').primaryKey(),
        key: pgText('key').notNull().unique(),
        value: pgText('value').notNull(),
        description: pgText('description'),
        createdAt: pgTimestamp('created_at').notNull().defaultNow(),
        updatedAt: pgTimestamp('updated_at').notNull().defaultNow()
      })
    case 'd1':
    default: // SQLite or D1
      return sqliteTable('system_config', {
        id: integer('id').primaryKey(),
        key: text('key').notNull().unique(),
        value: text('value').notNull(),
        description: text('description'),
        createdAt: integer('created_at', { mode: 'timestamp' }).notNull().default(sql`CURRENT_TIMESTAMP`),
        updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull().default(sql`CURRENT_TIMESTAMP`)
      })
  }
}

export const systemConfig = createSystemConfig()

export type SystemConfig = typeof systemConfig.$inferSelect
export type NewSystemConfig = typeof systemConfig.$inferInsert