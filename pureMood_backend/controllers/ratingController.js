const Specialist = require('../models/Specialist');

// Rate a specialist
exports.rateSpecialist = async (req, res) => {
  try {
    const { specialist_id, rating } = req.body;
    const patient_id = req.user.userId;

    // Validate rating
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    // Check if specialist exists
    const specialist = await Specialist.findByPk(specialist_id);
    if (!specialist) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    // Calculate new rating
    const currentRating = specialist.rating || 0;
    const currentReviews = specialist.total_reviews || 0;
    
    const totalRatingPoints = currentRating * currentReviews;
    const newTotalPoints = totalRatingPoints + rating;
    const newTotalReviews = currentReviews + 1;
    const newAverageRating = newTotalPoints / newTotalReviews;

    // Update specialist rating
    await specialist.update({
      rating: parseFloat(newAverageRating.toFixed(1)),
      total_reviews: newTotalReviews
    });

    // You can also store individual ratings in a separate table if needed
    // For now, we just update the aggregate

    res.json({
      message: 'Rating submitted successfully',
      new_rating: parseFloat(newAverageRating.toFixed(1)),
      total_reviews: newTotalReviews
    });

  } catch (error) {
    console.error('Error rating specialist:', error);
    res.status(500).json({ error: 'Failed to submit rating' });
  }
};

// Get specialist rating
exports.getSpecialistRating = async (req, res) => {
  try {
    const { specialist_id } = req.params;

    const specialist = await Specialist.findByPk(specialist_id, {
      attributes: ['rating', 'total_reviews']
    });

    if (!specialist) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    res.json({
      rating: specialist.rating || 0,
      total_reviews: specialist.total_reviews || 0
    });

  } catch (error) {
    console.error('Error getting rating:', error);
    res.status(500).json({ error: 'Failed to get rating' });
  }
};
