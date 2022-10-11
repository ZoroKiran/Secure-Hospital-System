const chatbot = require('../chatbot/chatbot')
module.exports = app =>{

    app.get('/text_query/:text', async(req, res)=>{

        // const {}
        const userId = '1';
        const text = req.params.text;
        const resultQuery = await chatbot.textQuery(text, userId)
        // console.log(resultQuery)
        const resObj ={
            intentName: resultQuery.intent.displayName,
            userQuery: resultQuery.queryText,
            fulfillmentText: resultQuery.fulfillmentText

        }
        console.log(resObj)
        return res.json(resObj.fulfillmentText);
    })
    // app.post('/event_query', (req, res)=>{
    //     console.log(req)
    //     res.send("Text Query")
    // })
}