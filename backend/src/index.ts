import Fastify from 'fastify'
import cors from '@fastify/cors'
import { Server } from 'socket.io'
import 'dotenv/config'

// Create Fastify server instance
const app = Fastify({ logger: true })

// Allow cross-origin requests from Flutter app
app.register(cors, { origin: '*' })

// Basic health check route
app.get('/health', async () => {
  return { status: 'ok', message: 'Group Travel Safety API is running' }
})

// Start server on port 3000
const start = async () => {
  try {
    await app.listen({ port: 3000, host: '0.0.0.0' })
    console.log('Server running on http://localhost:3000')
  } catch (err) {
    app.log.error(err)
    process.exit(1)
  }
}

start()
