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

const createUser = async (req, res, next) => {
  try {
    const { full_name, phone, role, preferred_language } = req.body;
    if (!full_name || !phone) return res.status(400).json({ error: 'full_name and phone are required.' });
    const user = await User.create({ full_name, phone, role: role || 'user', preferred_language: preferred_language || 'he', is_verified: true });
    res.status(201).json({ user });
  } catch (err) { next(err); }
};

const updateUser = async (req, res, next) => {
  try {
    const allowed = ['full_name', 'phone', 'role', 'preferred_language', 'email', 'is_verified'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
    const user = await User.findByIdAndUpdate(req.params.id, updates, { new: true, runValidators: true });
    if (!user) return res.status(404).json({ error: 'User not found.' });
    res.json({ user });
  } catch (err) { next(err); }
};

const deleteUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found.' });
    res.json({ message: 'User deleted.' });
  } catch (err) { next(err); }
};

const getAllLawyers = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyers = await Lawyer.find({}).select('full_name phone email is_available is_verified created_at specializations license_number years_of_experience').sort({ created_at: -1 });
    res.json({ lawyers });
  } catch (err) { next(err); }
};

const createLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const { full_name, phone, email, license_number, specializations, years_of_experience } = req.body;
    if (!full_name || !phone || !email || !license_number) {
      return res.status(400).json({ error: 'full_name, phone, email, license_number are required.' });
    }
    const lawyer = await Lawyer.create({
      full_name, phone, email, license_number,
      specializations: specializations || [],
      years_of_experience: years_of_experience || 0,
      is_verified: true,
    });
    res.status(201).json({ lawyer });
  } catch (err) { next(err); }
};

const updateLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const allowed = ['full_name', 'phone', 'email', 'is_available', 'is_verified', 'specializations', 'license_number', 'years_of_experience', 'bio'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
    const lawyer = await Lawyer.findByIdAndUpdate(req.params.id, updates, { new: true, runValidators: true });
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    res.json({ lawyer });
  } catch (err) { next(err); }
};

const deleteLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyer = await Lawyer.findByIdAndDelete(req.params.id);
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    res.json({ message: 'Lawyer deleted.' });
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

const updateEmergencyLog = async (req, res, next) => {
  try {
    const Event = require('../models/EmergencyEvent');
    const allowed = ['status', 'assigned_lawyer_id'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
    const event = await Event.findByIdAndUpdate(req.params.id, updates, { new: true });
    if (!event) return res.status(404).json({ error: 'Event not found.' });
    res.json({ event });
  } catch (err) { next(err); }
};

const deleteEmergencyLog = async (req, res, next) => {
  try {
    const Event = require('../models/EmergencyEvent');
    const event = await Event.findByIdAndDelete(req.params.id);
    if (!event) return res.status(404).json({ error: 'Event not found.' });
    res.json({ message: 'Event deleted.' });
  } catch (err) { next(err); }
};

module.exports = {
  getAdminSettings, updateFixedOtpSetting,
  getAllUsers, createUser, updateUser, deleteUser,
  getAllLawyers, createLawyer, updateLawyer, deleteLawyer,
  getEmergencyLogs, updateEmergencyLog, deleteEmergencyLog,
};