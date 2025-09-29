const express = require('express');
const { registerPassenger, loginPassenger } = require('../controllers/passenger.controllers');
const { signupSchema, loginSchema, validate } = require('../controllers/validators/passenger.validators');

const router = express.Router();

router.post('/register', validate(signupSchema), registerPassenger);
router.post('/login', validate(loginSchema), loginPassenger);

module.exports = router;
