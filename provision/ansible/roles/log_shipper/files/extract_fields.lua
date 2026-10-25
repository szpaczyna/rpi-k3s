function extract(tag, timestamp, record)
    local log = record["log"]
    if log == nil then return 0, timestamp, record end

    -- auth.log: "... from <ip> ..."
    local ip = string.match(log, "from ([^ ]+)")
    if ip then record["src_ip"] = ip end

    -- fail2ban.log: "Ban <ip>" / "Unban <ip>"
    if string.match(log, "Ban ") then
        record["action"] = "Ban"
        local f2b_ip = string.match(log, "Ban ([^ ]+)")
        if f2b_ip then record["src_ip"] = f2b_ip end
    end
    if string.match(log, "Unban ") then
        record["action"] = "Unban"
        local f2b_ip = string.match(log, "Unban ([^ ]+)")
        if f2b_ip then record["src_ip"] = f2b_ip end
    end

    return 1, timestamp, record
end
