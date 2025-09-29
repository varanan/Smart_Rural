const express = require('express');
const { registerConnector, loginConnector } = require('../controllers/connector.controllers');

const router = express.Router();

router.post('/register', registerConnector);
router.post('/login', loginConnector);

module.exports = router;