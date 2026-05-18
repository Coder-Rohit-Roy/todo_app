const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const Task = require('./models/Task');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/todo_db';
mongoose.connect(MONGODB_URI)
  .then(() => console.log('MongoDB database connected successfully!'))
  .catch(err => {
    console.error('MongoDB database connection error:', err);
    console.log('Ensure MongoDB is running or configure the connection string in .env');
  });

// API Routes

// 1. Get all tasks
app.get('/api/tasks', async (req, res) => {
  try {
    const tasks = await Task.find().sort({ createdAt: -1 });
    res.status(200).json(tasks);
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving tasks', error: error.message });
  }
});

// 2. Create a new task
app.post('/api/tasks', async (req, res) => {
  try {
    const { title, description, category, dueDate, priority, status, isCompleted } = req.body;
    
    const newTask = new Task({
      title,
      description: description || '',
      category,
      dueDate,
      priority,
      status: status || 'To Do',
      isCompleted: isCompleted || false
    });

    const savedTask = await newTask.save();
    res.status(201).json(savedTask);
  } catch (error) {
    res.status(400).json({ message: 'Error creating task', error: error.message });
  }
});

// 3. Update a task
app.put('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    // If isCompleted is toggled, optionally automatically change status
    if (updateData.isCompleted !== undefined) {
      updateData.status = updateData.isCompleted ? 'Done' : 'To Do';
    } else if (updateData.status !== undefined) {
      updateData.isCompleted = updateData.status === 'Done';
    }

    const updatedTask = await Task.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!updatedTask) {
      return res.status(404).json({ message: 'Task not found' });
    }

    res.status(200).json(updatedTask);
  } catch (error) {
    res.status(400).json({ message: 'Error updating task', error: error.message });
  }
});

// 4. Delete a task
app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const deletedTask = await Task.findByIdAndDelete(id);

    if (!deletedTask) {
      return res.status(404).json({ message: 'Task not found' });
    }

    res.status(200).json({ message: 'Task deleted successfully', id });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting task', error: error.message });
  }
});

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
