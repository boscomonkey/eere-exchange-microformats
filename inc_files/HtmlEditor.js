function OnCommandExecute(s, e) {
    var value = e.parameter;
    switch (e.commandName) {
        case "InsertSpecialSymbol":
            InsertSpecialSymbol(s, value);
            break;
    }
}

function InsertSpecialSymbol(sender, symbol) {
    var selection = sender.GetSelection();
    selection.SetHtml(symbol);
}