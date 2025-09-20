const express = require('express');
const { refreshToken } = require('../controllers/auth.controllers');
const { refreshTokenSchema, validate } = require('../controllers/validators/driver.validators');

const router = express.Router();

router.post('/refresh', validate(refreshTokenSchema), refreshToken);

module.exports = router;