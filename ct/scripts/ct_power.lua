function onWheel(notches, x, y)
  if not Input.isControlPressed() or not Input.isAltPressed() then return false end

  local attackLine = getValue();
  local abilityType, startPos, endPos = getHoveredAbilityAt(x, y, attackLine);

  if not abilityType then return false end

  local update = updateAttackLine(notches, attackLine, startPos, endPos);

  if Input.isControlPressed() then
    return onWheelControl(abilityType, update);
  elseif Input.isAltPressed() then
    return onWheelAlt(abilityType, update);
  else
    return false; -- propagate event
  end
end

function onWheelControl(abilityType, update)
  if abilityType == "damage" or abilityType == "heal" or abilityType == "effect" then
    setValue(update(nbDice));
  elseif abilityType == "attack" then
    setValue(update(attackBonus));
  elseif abilityType == "powersave" then
    setValue(update(saveDC));
  elseif abilityType == "usage" then
    setValue(update(numberInRange(1, 6)));
  end
  return true;
end

function onWheelAlt(abilityType, update)
  if abilityType == "damage" or abilityType == "heal" or abilityType == "effect" then
    setValue(update(die({"4", "6", "8", "10", "12"})));
  elseif abilityType == "powersave" then
    setValue(update(stat({"strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"})));
  end
  return true;
end

--
-- Partially copied from 5E.pak/ct/scripts/ct_power.lua
--
function getHoveredAbilityAt(x, y, attackLine)
  local nMouseIndex = getIndexAt(x, y);
  local rPower = CombatManager2.parseAttackLine(attackLine);

  if rPower then
    for hoverAbility, v in pairs(rPower.aAbilities) do
      if (v.nStart <= nMouseIndex) and (nMouseIndex < v.nEnd) then
        return rPower.aAbilities[hoverAbility].sType, v.nStart, v.nEnd;
      end
    end
  end

  return nil;
end

--
-- Attack line update processing
--

function updateAttackLine(notches, attackLine, startPos, endPos)
  local prefix, middle, suffix = splitLine(attackLine, startPos, endPos);
  return function(transformFn)
    return prefix .. transformFn(notches, middle) .. suffix;
  end
end

--
-- Attack line updaters
--

function nbDice(notches, attackLine)
  return attackLine:gsub("(-?%d+)d(%d+)", function(qty, die)
    return "" .. math.max(1, (tonumber(qty) + notches)) .. "d" .. die;
  end);
end

function attackBonus(notches, attackLine)
  return attackLine:gsub("([-+]%d+)", function(bonus)
    local newBonus = tonumber(bonus) + notches;
    local sign = newBonus >= 0 and "+" or "";
    return sign .. newBonus;
  end);
end

function saveDC(notches, attackLine)
  return attackLine:gsub("(%d+)", function(dc)
    return "" .. math.max(0, (tonumber(dc) + notches));
  end);
end

--
-- Higher-level attack line updaters
--

function numberInRange(lowerBound, upperBound)
  return function(notches, attackLine)
    return attackLine:gsub("(%d+)", function(n)
      return "" .. math.max(lowerBound, math.min(upperBound, (tonumber(n) + notches)));
    end);
  end
end

function die(diceTypes)
  return function(notches, attackLine)
    return attackLine:gsub("(-?%d+)d(%d+)", function(qty, die)
      return "" .. qty .. "d" .. cycleValues(diceTypes, die, notches);
    end);
  end
end

function stat(statTypes)
  return function(notches, attackLine)
    return attackLine:gsub("(SAVEVS: )(%a+)(.+)", function(prefix, stat, suffix)
      return prefix .. cycleValues(statTypes, stat, notches) .. suffix;
    end);
  end
end

--
-- Helpers
--

function splitLine(line, startPos, endPos)
  local prefix = line:sub(0, startPos - 1);
  local middle = line:sub(startPos, endPos);
  local suffix = line:sub(endPos + 1);
  return prefix, middle, suffix;
end

function cycleValues(list, candidate, offset)
  for idx, item in ipairs(list) do
    if candidate == item then
      local newIdx = idx + offset;
      if newIdx < 1 then
        newIdx = math.fmod(math.abs(newIdx), #list);
        return list[#list - newIdx];
      elseif newIdx > #list then
        newIdx = math.fmod(newIdx, #list);
        return list[newIdx];
      else
        return list[newIdx];
      end
    end
  end
  return candidate;
end
