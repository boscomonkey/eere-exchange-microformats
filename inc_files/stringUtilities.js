if (!String.prototype.trim) {
    String.prototype.trim = function () {
        return this.replace(/^\s+|\s+$/g, '');
    }
}

String.prototype.isNullOrWhiteSpace = function () {
    if (this == null) return true;
    return this.replace(/\s/g, '').length < 1;
}

String.prototype.trimNbsp = function () {
    return this.replace(/^&nbsp;+|&nbsp;+$/g, '');
}

String.prototype.trimAllSpaces = function () {
    return this.stripHtml().trim();
}


String.prototype.stripHtml = function (allowed_tags) {
    if (!this) {
        return this;
    }
    else {
        return StripHtml(this, false, allowed_tags);
    }
}

/// Remove HTML from string with Regex.
function StripHtml(strSource, onlyIETags, allowed_tags) {
    if (!onlyIETags) {

        //&nbsp;
        strSource = strSource.replace(/&nbsp;/g, " ");

        ////html tags
        ////strSource = strSource.replace(/<(.|\n)*?>/gi, "");
        //strSource = strSource.replace(/<\w([^<\n])*?>/gi, "");
        //strSource = strSource.replace(/<\s*\/\s*\w\s*.*?>/gi, "");
        strSource = strip_tags(strSource, allowed_tags);

        //greater than
        strSource = strSource.replace(/&gt;/g, ">");

        //less than
        strSource = strSource.replace(/&lt;/g, "<");

        //ampersand
        strSource = strSource.replace(/&amp;/g, "&");

        //javascript
        strSource = strSource.replace(/javascript:/gi, ">");
    }

    //TODO: Find a better approach to paste from Word
    // remove extraneous text that is added when pasted from older versions of MS Word and/or Internet Explorer
    var addedWordTextToReplace = /Normal(.|\n)*?X-NONE(.|\n)*?X-NONE/gi;
    strSource = strSource.replace(addedWordTextToReplace, "");

    addedWordTextToReplace = /MicrosoftInternetExplorer4/gi;
    strSource = strSource.replace(addedWordTextToReplace, "");

    //remove any leading and trailing line breaks
    //strSource = strSource.trim();

    return strSource;
}

function strip_tags(input, allowed) {
    // modified by Arthur Shterenberg
    // +   original by: Kevin van Zonneveld
    // *     example 1: strip_tags('<p>Kevin</p> <br /><b>van</b> <i>Zonneveld</i>', '<i><b>');
    // *     returns 1: 'Kevin <b>van</b> <i>Zonneveld</i>'
    // *     example 2: strip_tags('<p>Kevin <img src="someimage.png" onmouseover="someFunction()">van <i>Zonneveld</i></p>', '<p>');
    // *     returns 2: '<p>Kevin van Zonneveld</p>'
    // *     example 3: strip_tags("<a href='http'>Kevin van Zonneveld</a>", "<a>");
    // *     returns 3: '<a href='http'>Kevin van Zonneveld</a>'
    // *     example 4: strip_tags('1 < 5 5 > 1');
    // *     returns 4: '1 < 5 5 > 1'
    // *     example 5: strip_tags('1 <br/> 1');
    // *     returns 5: '1  1'
    // *     example 6: strip_tags('1 <br/> 1', '<br>');
    // *     returns 6: '1  1'
    // *     example 7: strip_tags('1 <br/> 1', '<br><br/>');
    // *     returns 7: '1 <br/> 1'
    allowed = (((allowed || "") + "").toLowerCase().match(/<[a-z][a-z0-9]*>/g) || []).join(''); // making sure the allowed arg is a string containing only tags in lowercase (<a><b><c>)
    var tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi,
        openp = /<p\b[^>]*>/gi,
        closep = /<\/p\b[^>]*>/gi,
        extras = /<!--[\s\S]*?-->|<!DOCTYPE[\s\S]*?>/gi; //strip html comments <!-- --> and <!DOCTYPE> tags
    return input.replace(extras, '').replace(openp, '<p>').replace(closep, '</p>').replace(tags, function ($0, $1) {
        return allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 ? $0 : '';
    });
}


//handle text pasted from Word for ASPxHtmlEditor Rich Textbox control
//make sure to add the following to ASPxHtmlEditor control's client side events definitions <ClientSideEvents HtmlChanged="pasteWordOnHtmlChanged" CommandExecuted="pastWordOnCommandExecuted" />

var pasteWordProcess = 1;
var pasteWordText = "";
var pasteWordRes = null;
var pasteWordAllowedTags = '<p><br><strong><b><em><i><sub><sup>';

function pasteWordOnHtmlChanged(s, e) {
    if (pasteWordProcess == 2) {
        pasteWordProcess = 3;
        pasteWordText = s.GetHtml();
        if (pasteWordText == "")
            pasteWordText = " "
        pasteWordRes = {
            html: strip_tags(pasteWordText.replace(/&nbsp;/g, " "), pasteWordAllowedTags), // pasteWordText.stripHtml(pasteWordAllowedTags),
            stripFontFamily: true
        };
        s.SetHtml(" ");
        s.ExecuteCommand(ASPxClientCommandConsts.PASTEFROMWORD_COMMAND, pasteWordRes);
    }
    //else {
    //    var htmlText = s.GetHtml();
    //    s.SetHtml(htmlText.stripHtml());
    //}
}

function pasteWordOnCommandExecuted(s, e) {
    if (e.commandName == ASPxClientCommandConsts.KBPASTE_COMMAND) {
        pasteWordProcess = 2;
        return;
    }
    if (e.commandName == ASPxClientCommandConsts.PASTE_COMMAND) {
        pasteWordProcess = 2;
        pasteWordOnHtmlChanged(s);
    }
    if (e.commandName == ASPxClientCommandConsts.PASTEFROMWORD_COMMAND) {
        pasteWordProcess = 3;
        s.ExecuteCommand(ASPxClientCommandConsts.PASTEHTML_COMMAND, " ");
        return;
    }
    if (e.commandName == ASPxClientCommandConsts.PASTEHTML_COMMAND) {
        pasteWordProcess = 1;
    }
}