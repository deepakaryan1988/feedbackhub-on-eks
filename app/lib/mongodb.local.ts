import { MongoClient, Db } from 'mongodb'

let client: MongoClient | null = null
let dbConnection: Db | null = null

async function connectToDatabase() {
  if (dbConnection) {
    return dbConnection
  }

  try {
    // For local development, use environment variable or default to host.docker.internal
    const mongoUri = process.env.MONGODB_URI || 'mongodb://host.docker.internal:27017/feedbackhub'
    
    if (process.env.MONGODB_URI) {
      console.log('✅ Using MONGODB_URI from environment variable (local environment)')
    } else {
      console.log('✅ Using local MongoDB (host.docker.internal:27017)')
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

export function mongoConfig() {
  return {
    uri: process.env.MONGODB_URI || 'host.docker.internal:27017',
    database: 'feedbackhub',
    username: 'from-uri',
    environment: process.env.NODE_ENV || 'development',
    strategy: 'local-mongodb'
  }
}
