class Token {
    [string]$Type;
    [char[]]$TokenContent;

    Token([char[]]$Content) {
        $this.TokenContent = $Content;
        $this.Type = "argument";
    }

    [string]ToString(){
        return [string]($this.TokenContent -join "")
    }
}
