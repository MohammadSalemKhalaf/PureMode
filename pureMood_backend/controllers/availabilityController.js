const SpecialistAvailability = require('../models/SpecialistAvailability');
const Specialist = require('../models/Specialist');

// ====== Get Specialist's Availability ======
exports.getMyAvailability = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    
    // Get specialist_id from user_id
    const specialist = await Specialist.findOne({ where: { user_id } });
    
    if (!specialist) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    const availability = await SpecialistAvailability.findAll({
      where: { specialist_id: specialist.specialist_id },
      order: [['day_of_week', 'ASC']]
    });

    res.json({ availability });
  } catch (err) {
    console.error('Error fetching availability:', err);
    res.status(500).json({ error: 'Failed to fetch availability' });
  }
};

// ====== Add/Update Availability ======
exports.setAvailability = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { day_of_week, start_time, end_time, is_available } = req.body;

    // Validate input
    if (!day_of_week || !start_time || !end_time) {
      return res.status(400).json({ error: 'day_of_week, start_time, and end_time are required' });
    }

    if (day_of_week < 1 || day_of_week > 7) {
      return res.status(400).json({ error: 'day_of_week must be between 1 and 7' });
    }

    // Get specialist_id
    const specialist = await Specialist.findOne({ where: { user_id } });
    
    if (!specialist) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    // Check if availability exists for this day
    const existing = await SpecialistAvailability.findOne({
      where: {
        specialist_id: specialist.specialist_id,
        day_of_week
      }
    });

    let availability;
    if (existing) {
      // Update
      await existing.update({
        start_time,
        end_time,
        is_available: is_available !== undefined ? is_available : true
      });
      availability = existing;
    } else {
      // Create
      availability = await SpecialistAvailability.create({
        specialist_id: specialist.specialist_id,
        day_of_week,
        start_time,
        end_time,
        is_available: is_available !== undefined ? is_available : true
      });
    }

    res.json({ 
      message: 'Availability set successfully',
      availability 
    });
  } catch (err) {
    console.error('Error setting availability:', err);
    res.status(500).json({ error: 'Failed to set availability' });
  }
};

// ====== Toggle Availability (Enable/Disable) ======
exports.toggleAvailability = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { day_of_week } = req.body;

    if (!day_of_week) {
      return res.status(400).json({ error: 'day_of_week is required' });
    }

    // Get specialist_id
    const specialist = await Specialist.findOne({ where: { user_id } });
    
    if (!specialist) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    // Find availability
    const availability = await SpecialistAvailability.findOne({
      where: {
        specialist_id: specialist.specialist_id,
        day_of_week
      }
    });

    if (!availability) {
      return res.status(404).json({ error: 'Availability not found for this day' });
    }

    // Toggle
    await availability.update({
      is_available: !availability.is_available
    });

    res.json({ 
      message: 'Availability toggled successfully',
      availability 
    });
  } catch (err) {
    console.error('Error toggling availability:', err);
    res.status(500).json({ error: 'Failed to toggle availability' });
  }
};

// ====== Delete Availability ======
exports.deleteAvailability = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { day_of_week } = req.params;

    // Get specialist_id
    const specialist = await Specialist.findOne({ where: { user_id } });
    
    if (!specialist) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    // Delete
    const deleted = await SpecialistAvailability.destroy({
      where: {
        specialist_id: specialist.specialist_id,
        day_of_week
      }
    });

    if (deleted === 0) {
      return res.status(404).json({ error: 'Availability not found' });
    }

    res.json({ message: 'Availability deleted successfully' });
  } catch (err) {
    console.error('Error deleting availability:', err);
    res.status(500).json({ error: 'Failed to delete availability' });
  }
};

// ====== Set Multiple Days at Once ======
exports.setBulkAvailability = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { availabilities } = req.body; // Array of {day_of_week, start_time, end_time, is_available}

    if (!Array.isArray(availabilities)) {
      return res.status(400).json({ error: 'availabilities must be an array' });
    }

    // Get specialist_id
    const specialist = await Specialist.findOne({ where: { user_id } });
    
    if (!specialist) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    const results = [];
    
    for (const avail of availabilities) {
      const { day_of_week, start_time, end_time, is_available } = avail;
      
      if (!day_of_week || !start_time || !end_time) continue;

      // Check if exists
      const existing = await SpecialistAvailability.findOne({
        where: {
          specialist_id: specialist.specialist_id,
          day_of_week
        }
      });

      if (existing) {
        await existing.update({
          start_time,
          end_time,
          is_available: is_available !== undefined ? is_available : true
        });
        results.push(existing);
      } else {
        const created = await SpecialistAvailability.create({
          specialist_id: specialist.specialist_id,
          day_of_week,
          start_time,
          end_time,
          is_available: is_available !== undefined ? is_available : true
        });
        results.push(created);
      }
    }

    res.json({ 
      message: 'Bulk availability set successfully',
      count: results.length,
      availabilities: results
    });
  } catch (err) {
    console.error('Error setting bulk availability:', err);
    res.status(500).json({ error: 'Failed to set bulk availability' });
  }
};
