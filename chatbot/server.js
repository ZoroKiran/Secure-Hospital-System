const express = require('express');
const port = 3030;
const bodyParser = require('body-parser');
const cors = require('cors');
const app = express();

app.use(bodyParser.urlencoded({extended :false}))
app.use(bodyParser.json())
app.get('/server', (req, res)=>{
    res.send("Hello world")
})

require('./routes/server-routes')(app)

app.listen(port, ()=>{
    console.log("server is running on "+port)
})