import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const system = sqliteTable('system', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull().unique(),
  value: text('value').notNull(),
  activity: integer('activity', { mode: 'boolean' }).notNull().default(false),
  createdAt: text('created_at').notNull().default('CURRENT_TIMESTAMP'),
  updatedAt: text('updated_at').notNull().default('CURRENT_TIMESTAMP')
}); 