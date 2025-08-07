import { NextRequest, NextResponse } from 'next/server'
import { getDb } from '../../lib/mongodb'
import { Feedback, FeedbackFormData, ApiResponse } from '../../types/feedback'

export async function GET(): Promise<NextResponse<ApiResponse<Feedback[]>>> {
  try {
    const db = await getDb()
    const collection = db.collection('feedbacks')
    
    const feedbacks = await collection
      .find({})
      .sort({ createdAt: -1 })
      .limit(50)
      .toArray()

    return NextResponse.json({
      success: true,
      data: feedbacks as unknown as Feedback[]
    })
  } catch (error) {
    console.error('Database connection failed:', error)
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to database'
      },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest): Promise<NextResponse<ApiResponse<Feedback>>> {
  try {
    const body: FeedbackFormData = await request.json()
    
    // Validate input
    if (!body.name || !body.message) {
      return NextResponse.json(
        {
          success: false,
          error: 'Name and message are required'
        },
        { status: 400 }
      )
    }

    const feedback: Omit<Feedback, '_id'> = {
      name: body.name.trim(),
      message: body.message.trim(),
      createdAt: new Date()
    }

    const db = await getDb()
    const collection = db.collection('feedbacks')
    
    const result = await collection.insertOne(feedback)
    
    const insertedFeedback: Feedback = {
      _id: result.insertedId.toString(),
      ...feedback
    }

    return NextResponse.json({
      success: true,
      data: insertedFeedback
    }, { status: 201 })
  } catch (error) {
    console.error('Error creating feedback:', error)
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to create feedback'
      },
      { status: 500 }
    )
  }
} 