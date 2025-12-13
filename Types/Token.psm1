class Token {
    [string]$Type;
    [char[]]$TokenContent;
    [boolean]$HasValue;

    Token([char[]]$Content, [boolean]$HasValue) {
        $this.TokenContent = $Content;
        $this.Type = "argument";
        $this.HasValue = $HasValue;
    }

    [string]ToString(){
        return [string]($this.TokenContent -join "")
    }
}
