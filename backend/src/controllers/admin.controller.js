const User    = require('../models/User');
const Lawyer  = require('../models/Lawyer');
const Event   = require('../models/EmergencyEvent');

const getAdminSettings = async (req, res, next) => {
  try {
    const enableFixedOtpForAdmins = process.env.ENABLE_FIXED_OTP_FOR_ADMINS === 'true';
    
    res.status(200).json({
      enableFixedOtpForAdmins,
      serverStatus: 'Online',
      mongoDbStatus: 'Connected',
      appVersion: 'v1.2.4',
    });
  } catch (err) {
    next(err);
  }
};

const updateFixedOtpSetting = async (req, res, next) => {
  try {
    const { enable } = req.body;
    if (typeof enable !== 'boolean') {
      return res.status(400).json({ error: 'Invalid value for enable. Must be a boolean.' });
    }
    process.env.ENABLE_FIXED_OTP_FOR_ADMINS = enable.toString();
    console.log(`[ADMIN] ENABLE_FIXED_OTP_FOR_ADMINS set to: ${enable}`);
    res.status(200).json({ message: 'Fixed OTP setting updated successfully.', enableFixedOtpForAdmins: enable });
  } catch (err) {
    next(err);
  }
};

const getAllUsers = async (req, res, next) => {
  try {
    const users = await User.find({}).select('full_name phone role is_verified created_at preferred_language').sort({ created_at: -1 });
    res.json({ users });
  } catch (err) { next(err); }
};

const getAllLawyers = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyers = await Lawyer.find({}).select('full_name phone is_available is_verified created_at specializations').sort({ created_at: -1 });
    res.json({ lawyers });
  } catch (err) { next(err); }
};

const getEmergencyLogs = async (req, res, next) => {
  try {
    const Event = require('../models/EmergencyEvent');
    const events = await Event.find({}).sort({ triggered_at: -1 }).limit(100)
      .populate('user_id', 'full_name phone')
      .populate('assigned_lawyer_id', 'full_name phone');
    res.json({ events });
  } catch (err) { next(err); }
};

module.exports = {
  getAdminSettings,
  updateFixedOtpSetting,
  getAllUsers,
  getAllLawyers,
  getEmergencyLogs,
};