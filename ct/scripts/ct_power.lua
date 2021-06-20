function onWheel(notches, x, y)
    if not Input.isControlPressed() then
        return false; -- propagate event
    end

    local attackLine = getValue();
    local abilityType, startPos, endPos = getHoveredAbilityAt(x, y, attackLine);

    if abilityType == "damage" then
        setValue(incrementSectionBy(notches, attackLine, startPos, endPos, incrementDamageBy));
        return true;
    elseif abilityType == "attack" then
        setValue(incrementSectionBy(notches, attackLine, startPos, endPos, incrementAttackBy));
        return true;
    else
        return false; -- propagate event
    end
end

-- Partially copied from 5E.pak/ct/scripts/ct_power.lua

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

function incrementSectionBy(notches, attackLine, startPos, endPos, transformFn)
    local prefix, middle, suffix = splitAttackLine(attackLine, startPos, endPos);
    return prefix .. transformFn(notches, middle) .. suffix;
end

function splitAttackLine(attackLine, startPos, endPos)
    local prefix = attackLine:sub(0, startPos-1);
    local middle = attackLine:sub(startPos, endPos);
    local suffix = attackLine:sub(endPos+1);
    return prefix, middle, suffix;
end

function incrementDamageBy(notches, attackLine)
    return attackLine:gsub("(-?%d+)d(%d+)", function(qty, die)
        return "" .. (tonumber(qty) + notches) .. "d" .. die;
    end);
end

function incrementAttackBy(notches, attackLine)
    return attackLine:gsub("([-+]%d+)", function(bonus)
        local newBonus = tonumber(bonus) + notches;
        local sign = newBonus >= 0 and "+" or ""; 
        return sign .. newBonus;
    end);
end