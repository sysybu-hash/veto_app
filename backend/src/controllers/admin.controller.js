const User = require('../models/User');

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
    console.log([ADMIN] ENABLE_FIXED_OTP_FOR_ADMINS set to: );
    res.status(200).json({ message: 'Fixed OTP setting updated successfully.', enableFixedOtpForAdmins: enable });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getAdminSettings,
  updateFixedOtpSetting,
};
