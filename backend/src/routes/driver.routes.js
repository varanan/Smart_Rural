const express = require('express');
const { signupDriver, loginDriver } = require('../controllers/driver.controllers');
const { signupSchema, loginSchema, validate } = require('../controllers/validators/driver.validators');

const router = express.Router();

router.post('/signup', validate(signupSchema), signupDriver);
router.post('/login', validate(loginSchema), loginDriver);

module.exports = router;
