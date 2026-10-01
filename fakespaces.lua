-- Put a real U+0020 glyph (taken out of the gap's width) into each word gap so PDF
-- text extractors used by ATS parsers see spaces; the layout does not move.
local GLYPH, GLUE, KERN = node.id("glyph"), node.id("glue"), node.id("kern")
local HLIST, VLIST = node.id("hlist"), node.id("vlist")
local WORD_GLUE = { [0] = true, [13] = true, [14] = true }

local function space_width(fid)
  local f = font.getfont(fid) or (fonts and fonts.hashes and fonts.hashes.identifiers[fid])
  local c = f and f.characters and f.characters[32]
  return c and c.width
end

local function process(head)
  local n = head
  while n do
    local id = n.id
    if id == HLIST or id == VLIST then
      n.head = process(n.head)
    elseif id == GLUE and WORD_GLUE[n.subtype] then
      local p = n.prev
      if p and p.id == KERN then p = p.prev end
      if p and p.id == GLYPH then
        local w = space_width(p.font)
        if w and n.width >= w then
          local g = node.new(GLYPH)
          g.font, g.char = p.font, 32
          n.width = n.width - w
          head = node.insert_before(head, n, g)
        end
      end
    end
    n = n.next
  end
  return head
end

luatexbase.add_to_callback("pre_shipout_filter", process, "fakespaces")
