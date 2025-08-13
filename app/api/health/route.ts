import { NextResponse } from 'next/server'
import { getDb, mongoConfig } from '../../lib/mongodb'

// Force dynamic rendering
export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const config = mongoConfig()
    
    // Check if we're in build-time
    const isBuildTime = config.strategy === 'build-time-safe'
    
    if (isBuildTime) {
      console.log('🔧 Build-time detected - returning mock health status')
      return NextResponse.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'feedbackhub',
        version: '1.0.0',
        database: {
          status: 'build-time-safe',
          environment: config.environment,
          database: config.database,
          user: config.username,
          cluster: 'build-time'
        }
      })
    }

    // Runtime execution - actually check MongoDB
    try {
      const db = await getDb()
      
      // Simple connection test - just verify the database object exists
      if (db && typeof db === 'object') {
        return NextResponse.json({
          status: 'healthy',
          timestamp: new Date().toISOString(),
          service: 'feedbackhub',
          version: '1.0.0',
          database: {
            status: 'connected',
            environment: config.environment,
            database: config.database,
            user: config.username,
            cluster: config.strategy === 'aws-secrets-manager' ? 'aws' : 'local'
          }
        })
      } else {
        throw new Error('Database object is invalid')
      }
    } catch (dbError) {
      console.error('❌ Database health check failed:', dbError)
      
      return NextResponse.json({
        status: 'degraded',
        timestamp: new Date().toISOString(),
        service: 'feedbackhub',
        version: '1.0.0',
        database: {
          status: 'disconnected',
          environment: config.environment,
          database: config.database,
          user: config.username,
          cluster: config.strategy === 'aws-secrets-manager' ? 'aws' : 'local',
          error: dbError instanceof Error ? dbError.message : 'Unknown error'
        }
      }, { status: 503 })
    }
  } catch (error) {
    console.error('❌ Health check failed:', error)
    
    return NextResponse.json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      service: 'feedbackhub',
      version: '1.0.0',
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
} 