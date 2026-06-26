import Machine from '../models/Machine.js';

// @desc    Create a new machine record
// @route   POST /api/machines
// @access  Private
export const createMachine = async (req, res) => {
  try {
    const { name, type, status, notes } = req.body;

    if (!name || !type) {
      return res.status(400).json({ message: 'Machine name and type are required' });
    }

    const machine = await Machine.create({
      shopId: req.user.shopId,
      name,
      type,
      status: status || 'Working',
      notes: notes || '',
    });

    res.status(201).json(machine);
  } catch (error) {
    console.error('Create machine error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all machines for a shop
// @route   GET /api/machines
// @access  Private
export const getMachines = async (req, res) => {
  try {
    const search = req.query.search || '';
    const filter = { shopId: req.user.shopId };

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { type: { $regex: search, $options: 'i' } },
      ];
    }

    const machines = await Machine.find(filter).sort({ createdAt: -1 });
    res.json(machines);
  } catch (error) {
    console.error('Get machines error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get details of a single machine
// @route   GET /api/machines/:id
// @access  Private
export const getMachineById = async (req, res) => {
  try {
    const machine = await Machine.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!machine) {
      return res.status(404).json({ message: 'Machine not found' });
    }

    res.json(machine);
  } catch (error) {
    console.error('Get machine by ID error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a machine details
// @route   PUT /api/machines/:id
// @access  Private
export const updateMachine = async (req, res) => {
  try {
    const machine = await Machine.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!machine) {
      return res.status(404).json({ message: 'Machine not found' });
    }

    const { name, type, status, notes } = req.body;

    if (name) machine.name = name;
    if (type) machine.type = type;
    if (status) machine.status = status;
    if (notes !== undefined) machine.notes = notes;

    const updatedMachine = await machine.save();
    res.json(updatedMachine);
  } catch (error) {
    console.error('Update machine error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a machine record
// @route   DELETE /api/machines/:id
// @access  Private
export const deleteMachine = async (req, res) => {
  try {
    const machine = await Machine.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!machine) {
      return res.status(404).json({ message: 'Machine not found' });
    }

    await Machine.deleteOne({ _id: machine._id });
    res.json({ message: 'Machine deleted successfully' });
  } catch (error) {
    console.error('Delete machine error:', error);
    res.status(500).json({ message: error.message });
  }
};
