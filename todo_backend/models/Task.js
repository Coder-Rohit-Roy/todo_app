const mongoose = require('mongoose');

const TaskSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Please add a task title'],
    trim: true,
  },
  description: {
    type: String,
    trim: true,
    default: '',
  },
  category: {
    type: String,
    enum: ['Work', 'Study', 'Personal'],
    required: [true, 'Please specify a category (Work, Study, Personal)'],
  },
  dueDate: {
    type: Date,
    required: [true, 'Please specify a due date and time'],
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High'],
    required: [true, 'Please specify a priority (Low, Medium, High)'],
  },
  status: {
    type: String,
    enum: ['To Do', 'In Progress', 'Done'],
    default: 'To Do',
  },
  isCompleted: {
    type: Boolean,
    default: false,
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Task', TaskSchema);
