const mongoose = require('mongoose');

const AppSettingSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      unique: true,
      required: true,
      index: true,
    },
    value: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    updated_by: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },
  },
  { timestamps: true, versionKey: false },
);

module.exports = mongoose.model('AppSetting', AppSettingSchema);
