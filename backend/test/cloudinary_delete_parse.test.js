const test = require('node:test');
const assert = require('node:assert/strict');

const {
  parseCloudinaryUrl,
} = require('../src/services/media/cloudinaryDelete.service');

test('parseCloudinaryUrl — image upload with version', () => {
  const parsed = parseCloudinaryUrl(
    'https://res.cloudinary.com/demo/image/upload/v1312461204/veto/vault/sample.jpg',
  );
  assert.ok(parsed);
  assert.equal(parsed.cloudName, 'demo');
  assert.equal(parsed.resourceType, 'image');
  assert.equal(parsed.publicId, 'veto/vault/sample');
});

test('parseCloudinaryUrl — video without version', () => {
  const parsed = parseCloudinaryUrl(
    'https://res.cloudinary.com/demo/video/upload/veto/vault/clip.mp4',
  );
  assert.ok(parsed);
  assert.equal(parsed.resourceType, 'video');
  assert.equal(parsed.publicId, 'veto/vault/clip');
});

test('parseCloudinaryUrl — raw keeps extension', () => {
  const parsed = parseCloudinaryUrl(
    'https://res.cloudinary.com/demo/raw/upload/v1/veto/vault/doc.pdf',
  );
  assert.ok(parsed);
  assert.equal(parsed.resourceType, 'raw');
  assert.equal(parsed.publicId, 'veto/vault/doc.pdf');
});

test('parseCloudinaryUrl — rejects non-cloudinary', () => {
  assert.equal(parseCloudinaryUrl('https://example.com/file.jpg'), null);
  assert.equal(parseCloudinaryUrl('data:text/plain;base64,YQ=='), null);
  assert.equal(parseCloudinaryUrl(''), null);
});
