function onInit()
  CombatRecordManager.setRecordTypePostAddCallback("npc", proxy(CombatManager2.onNPCPostAdd, upcastCantrips));
end

--
-- Intercepts calls to subject function and executes an advice after the call.
--

function proxy(subjectFn, afterAdvice)
  return function(...)
    local returnValue = subjectFn(...);
    afterAdvice(...);
    return returnValue;
  end
end

--
-- Gets the spellcaster level from the "Spellcasting" Trait then loops through
-- cantrips while incrementing the number of DMG or HEAL dice.
--

function upcastCantrips(tCustom)
  local nodeEntry = tCustom.nodeCT;
  local notches = getNbNotches(getSpellcasterLevel(nodeEntry));
  if notches < 1 then return end
  
  forEachCantrip(nodeEntry, function(attackLine, setValue)
    if attackLine:find("DMG:") or attackLine:find("HEAL:") then
      setValue(updateNbDice(notches, attackLine));
    end
  end);
end

--
-- Reads the nodeEntry's "Spellcasting" trait and returns the spellcaster
-- level or 0.
--

function getSpellcasterLevel(nodeEntry)
  for _, nodePower in pairs(DB.getChildren(nodeEntry, "traits")) do
    local name = StringManager.trim(DB.getValue(nodePower, "name", ""):lower());
    if name == "spellcasting" then
      local desc = DB.getValue(nodePower, "desc", "");
      local level = desc:match("(%d+)..-level spellcaster") or 0;
      return tonumber(level);
    end
  end
  return 0;
end

--
-- Determines the number of times ("notches") cantrips should be incremented
-- based on the spellcaster's level. Uses standard thresholds of 5th, 11th
-- and 17th level.
--

function getNbNotches(spellcasterLevel)
  local steps = { 17, 11, 5, 0 };
  for idx, limit in ipairs(steps) do
    if spellcasterLevel >= limit then
      return #steps - idx;
    end
  end
  return 0;
end

--
-- Loops through all cantrips found in the nodeEntry and calls function "f"
-- for each, passing it the attack line and a setValue callback to modify the
-- entry's power in the database.
--

function forEachCantrip(nodeEntry, f)
  for _, spellTrait in pairs({"spells", "innatespells"}) do
    for _, nodePower in pairs(DB.getChildren(nodeEntry, spellTrait)) do
      local attackLine = DB.getValue(nodePower, "value", "");
      if attackLine:find("cantrip") then
        local setValue = function(...) DB.setValue(nodePower, "value", "string", ...) end
        f(attackLine, setValue);
      end
    end
  end
end

--
-- Attack line updaters
--

function updateNbDice(notches, attackLine)
  return attackLine:gsub("(-?%d+)d(%d+)", function(qty, die)
    return string.format("%dd%s", math.max(1, (tonumber(qty) + notches)), die);
  end);
end
