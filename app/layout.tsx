import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import ClientLayout from './components/layout/client-layout'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'FeedbackHub - Modern Feedback Platform',
  description: 'A modern, accessible feedback platform built with Next.js and shadcn/ui',
  keywords: ['feedback', 'nextjs', 'shadcn', 'ui', 'modern'],
  authors: [{ name: 'FeedbackHub Team' }],
}

export const viewport = {
  width: 'device-width',
  initialScale: 1,
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${inter.className} antialiased`}>
        <ClientLayout>
          {children}
        </ClientLayout>
      </body>
    </html>
  )
} 