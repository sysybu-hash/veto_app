const jwt = require('jsonwebtoken'); console.log(jwt.sign({ id: '123', role: 'admin' }, process.env.JWT_SECRET || 'secret', { expiresIn: '1d' }));
