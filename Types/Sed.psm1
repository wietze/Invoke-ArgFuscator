class SedStatement {
    $FORMAT = [regex]"^s/(?<Find>(?:[^/\\]|\\(?:\\|/))+?)/(?<Replace>(?:[^/\\]|\\(?:\\|/))*?)/(?<Options>[ig])?$"
    [string]$Find;
    [string[]]$Replace;
    [boolean]$CaseInsensitive;

    SedStatement([string]$Statement) {
        $results = $this.FORMAT.Matches($Statement)
        $this.Find = [regex]::Replace($results.Groups[1].Value, "/\\(\\|/)/g", "`1");
        $this.Replace = [regex]::Replace($results.Groups[2].Value, "/\\(\\|/)/g", "`1").Split("|");
        $this.CaseInsensitive = ($null -eq $results.Groups[3].Value) -or $results.Groups[3].Value.IndexOf('i') -ge 0;
    }

    [int32]StringIndex([string]$Content){
        if($this.CaseInsensitive){
            return $Content.ToUpper().IndexOf($this.Find.ToUpper());
        }
        return $Content.IndexOf($this.Find);
    }
}
