'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

test('agora cloud recording reports unconfigured when env missing', () => {
  const svcPath = require.resolve('../src/services/agoraCloudRecording.service.js');
  delete require.cache[svcPath];

  delete process.env.AGORA_APP_ID;
  delete process.env.AGORA_APP_CERTIFICATE;
  delete process.env.AGORA_RESTFUL_CUSTOMER_ID;
  delete process.env.AGORA_RESTFUL_CUSTOMER_SECRET;
  delete process.env.AGORA_CR_S3_BUCKET;
  delete process.env.AGORA_CR_S3_ACCESS_KEY;
  delete process.env.AGORA_CR_S3_SECRET_KEY;
  delete process.env.AGORA_CR_S3_REGION_NUM;

  const agoraCr = require(svcPath);
  assert.equal(agoraCr.isCloudRecordingConfigured(), false);
});
