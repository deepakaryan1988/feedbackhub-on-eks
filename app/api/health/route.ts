import { NextResponse } from 'next/server'
import { getDb, mongoConfig } from '../../lib/mongodb'

export async function GET() {
  try {
    const config = mongoConfig()
    
    // Handle build-time scenario
    if (config.strategy === 'build-time-mock') {
      return NextResponse.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'feedbackhub',
        version: '1.0.0',
        database: {
          status: 'build-time',
          environment: config.environment,
          database: config.database,
          user: config.username,
          cluster: 'build-time'
        }
      })
    }
    
    // Simple health check - respond immediately
    const basicHealth = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'feedbackhub',
      version: '1.0.0',
      database: {
        status: 'checking',
        environment: config.environment,
        database: config.database,
        user: config.username,
        cluster: config.uri.split('@')[1]?.split('/')[0] || 'unknown'
      }
    }
    
    // Try to check MongoDB connection (but don't fail the health check if it's slow)
    try {
      const db = await getDb()
      await db.admin().ping()
      
      return NextResponse.json({
        ...basicHealth,
        database: {
          ...basicHealth.database,
          status: 'connected'
        }
      })
    } catch (dbError) {
      console.warn('Database health check failed, but service is still healthy:', dbError)
      return NextResponse.json({
        ...basicHealth,
        database: {
          ...basicHealth.database,
          status: 'disconnected',
          error: dbError instanceof Error ? dbError.message : 'Database connection failed'
        }
      })
    }
  } catch (error) {
    console.error('Health check failed:', error)
    const config = mongoConfig()
    return NextResponse.json(
      {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        service: 'feedbackhub',
        version: '1.0.0',
        database: {
          status: 'disconnected',
          environment: config.environment,
          database: config.database,
          user: config.username,
          cluster: config.uri.split('@')[1]?.split('/')[0] || 'unknown',
          error: error instanceof Error ? error.message : 'Service health check failed'
        }
      },
      { status: 503 }
    )
  }
} 