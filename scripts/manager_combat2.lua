function onInit()
  -- Proxy CombatManage.addNPC function
	CombatManager.addNPC = addNPC(CombatManager.addNPC);
end

function addNPC(subjectFn)
  return function(sClass, nodeNPC, sName)
    local nodeEntry = subjectFn(sClass, nodeNPC, sName);

    local spellcasterLevel = parseSpellcasterLevel(nodeEntry);
    if spellcasterLevel then
      Debug.console(spellcasterLevel)
    end

    return nodeEntry;
  end
end

function parseSpellcasterLevel(nodeEntry)
  for _, nodePower in pairs(DB.getChildren(nodeEntry, "traits")) do
    local name = StringManager.trim(DB.getValue(nodePower, "name", ""):lower());
    if name == "spellcasting"then
      local desc = DB.getValue(nodePower, "desc", "");
      local level = desc:match("(%d+)..-level spellcaster") or 0;
      return tonumber(level);
    end
  end
  return nil;
end