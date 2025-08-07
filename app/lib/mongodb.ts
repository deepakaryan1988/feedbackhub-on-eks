import { MongoClient, Db } from 'mongodb'

let client: MongoClient | null = null
let dbConnection: Db | null = null

async function connectToDatabase() {
  if (dbConnection) {
    return dbConnection
  }

  try {
    const mongoUri = process.env.MONGODB_URI

    if (!mongoUri) {
      throw new Error('MONGODB_URI environment variable not set.')
    }

    client = new MongoClient(mongoUri)
    await client.connect()
    dbConnection = client.db()

    console.log('✅ Successfully connected to MongoDB.')
    return dbConnection
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error)
    throw new Error('Could not connect to the database.')
  }
}

export async function getDb(): Promise<Db> {
  const db = await connectToDatabase()
  if (!db) {
    throw new Error('Database not connected')
  }
  return db
}

export async function closeConnection(): Promise<void> {
  if (client) {
    await client.close()
    client = null
    dbConnection = null
    console.log('🔌 MongoDB connection closed.')
  }
}

// For health checks
export function mongoConfig() {
  return {
    uri: process.env.MONGODB_URI || 'Not Set',
    database: process.env.MONGODB_URI?.split('/').pop()?.split('?')[0] || 'Not Set',
    username: 'from-uri',
    environment: process.env.NODE_ENV || 'development',
    strategy: 'direct-uri'
  }
}

 