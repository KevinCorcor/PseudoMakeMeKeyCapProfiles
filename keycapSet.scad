use <MX_DES_Standard.scad>
use <MX_DES_Thumb.scad>
use <MX_DES_Convex.scad>

dishParameters = import(file = "dishParameters.json");
keyParameters = import(file = "keyParameters.json");
keyRows = import(file = "input.json").keyRows2;
//keyRows = import(file = "input.json").Single;

$radious = 0.95;


echo(keyParameters["Thumb"][24]);
module mjf_supports(size, gen_support, sprue_trim, sprue_trim_len, sprue_trim_wid) {
  extra_side = 3.5;
  extra_heigt = 0.1;
  $fn = 16;

  if (gen_support > 0) {
	color("red") {
		translate([0, 0, $radious]) {
			// connect sprues
			if (sprue_trim != true) {
				translate([0, -size/2 + $radious - 0.45, -$radious * 3])
					rotate([90, 0, 0])
					cylinder(h=sprue_trim_len + extra_side, r=$radious);
			}
			translate([$radious, -size/2 + $radious - 0.40, -$radious * 3])
				rotate([180, 90, 0])
				cylinder(h=sprue_trim_wid + extra_side, r=$radious);
			translate([0, -size/2 + $radious - 0.45, -$radious + extra_heigt])
				rotate([0, 180, 0])
				cylinder(h=$radious * 2 + extra_heigt, r=$radious);
		}
	}
  }
  children();
}

function contains(base, searchkey) = len(search(searchkey, base)) > 0;
function isDotsKey(setName, keyIdIndex) = contains(setName, "R2") && keyIdIndex == 1;
function SubSum(x = 0, Index = 0) = x[Index] + ((Index <= 0) 
    ? 0
    : SubSum(x = x, Index = Index - 1));
function Sum(x) = SubSum(x = x, Index = len(x) - 1);
function CollectColumnKeyCapLengthsFromRow(upperRowIndex, columnIndex) =
[
	for (rowIndex = [0:1:upperRowIndex])
		is_undef(keyRows[rowIndex].keycaps[columnIndex])
		? 0 
		: keyRows[rowIndex].isEnabled 
			? keyParameters[
				is_undef(keyRows[rowIndex].keycaps[columnIndex].keyType) 
					? keyRows[rowIndex].defaultKeyType 
					: keyRows[rowIndex].keycaps[columnIndex].keyType
				]
				[keyRows[rowIndex].keycaps[columnIndex].keyId].bottomLength + 2
			: 0 
];
function CollectColumnKeyCapWidthsFromRow(rowIndex, upperColumnIndex) =
[
	for (columnIndex = [0:1:upperColumnIndex])
		keyRows[rowIndex].isEnabled 
			? keyParameters[
				is_undef(keyRows[rowIndex].keycaps[columnIndex].keyType) 
					? keyRows[rowIndex].defaultKeyType 
					: keyRows[rowIndex].keycaps[columnIndex].keyType
			][keyRows[rowIndex].keycaps[columnIndex].keyId]
				.bottomWidth + 2
			: 0 
];

generateKeyCapRows();
module generateKeyCapRows()
{
	for (keyRowIndex = [0:1:len(keyRows) - 1])
	{
		isFirstRow = keyRowIndex == 0;
		isMultipleRows = len(keyRows) > 1;
		connectToPreviousRow = !isFirstRow && isMultipleRows;

		keyRow = keyRows[keyRowIndex];
 		if (keyRow.isEnabled)
		{
			// translate([ 0, 20 * keyRowIndex ])
			generateRow(keyRowIndex, keyRow.keycaps, keyRow.defaultKeyType);
		}
        if (keyRow.mirror)
        {
            mirror([1,0,0])
            generateRow(keyRowIndex, keyRow.keycaps, keyRow.defaultKeyType);
        }
	}
}

module generateRow(rowIndex, keyCaps, defaultKeyType)
{
	sprue_trim = ( rowIndex != 0 
		? false 
		: ( len(keyRows) > 1 
			? true
			: false)
	);
	for (keyCapIndex = [0:1:len(keyCaps) - 1])
	{
		keyCap = keyCaps[keyCapIndex];
		echo(keyCap);
		isHomeKey = is_undef(keyCap.isHomeKey) ? false : keyCap.isHomeKey;
        keyType = is_undef(keyCap.keyType) ? defaultKeyType : keyCap.keyType;
        keyId = keyCap.keyId;

        currentKeyCapWidth = keyParameters[keyType][keyId].bottomWidth;
 		columnKeyCapWidthsFromRow = CollectColumnKeyCapWidthsFromRow(rowIndex, keyCapIndex);
 		xSpacing = Sum(columnKeyCapWidthsFromRow) - (currentKeyCapWidth / 2);
		
        currentKeyCapLength = keyParameters[keyType][keyId].bottomLength;
 		columnKeyCapLengthsFromRow = CollectColumnKeyCapLengthsFromRow(rowIndex, keyCapIndex);
        // if (keyCapIndex == 0)
        // {
            ySpacing = Sum(columnKeyCapLengthsFromRow) - (currentKeyCapLength / 2);

			sprueKeyCap = rowIndex == 0 ? keyCap : keyRows[rowIndex - 1].keycaps[keyCapIndex];
			sprueKeyType = is_undef(sprueKeyCap.keyType) ? defaultKeyType : sprueKeyCap.keyType;
			// sprueKeyCapDim = sprueKeyType == "Convex" ? "bottomWidth":"bottomLength";
            translate([ xSpacing, ySpacing])
			mjf_supports(
				size=keyParameters[keyType][keyId].bottomLength,
				gen_support=1, 
				sprue_trim, 
				keyParameters[sprueKeyType][sprueKeyCap.keyId].bottomLength,
				keyParameters[sprueKeyType][sprueKeyCap.keyId].bottomWidth)
			rotate([0, 0, is_undef(keyCap.rotate) ? 0 : keyCap.rotate])
            mirror([keyCap.mirror ? 1 : 0, 0, 0])
			generateKeycap(keyId, isHomeKey, keyType);
        // }
        // if (keyCapIndex == 1)
        // {
        //     ySpacing = (Sum(columnKeyCapLengthsFromRow) - (currentKeyCapLength / 2)) + 3;
        //     translate([ xSpacing, ySpacing])
		// 	mjf_supports(size=keyParameters[keyType][keyId].bottomLength, gen_support=1, sprue_trim)
		// 	rotate([0, 0, is_undef(keyCap.rotate) ? 0 : keyCap.rotate])
        //     mirror([keyCap.mirror ? 1 : 0, 0, 0])
		// 	generateKeycap(keyId, isHomeKey, keyType);
        // }
        // if (keyCapIndex == 2)
        // {
        //     ySpacing = (Sum(columnKeyCapLengthsFromRow) - (currentKeyCapLength / 2)) + 5;
        //     translate([ xSpacing, ySpacing])
		// 	mjf_supports(size=keyParameters[keyType][keyId].bottomLength, gen_support=1, sprue_trim)
		// 	rotate([0, 0, is_undef(keyCap.rotate) ? 0 : keyCap.rotate])
        //     mirror([keyCap.mirror ? 1 : 0, 0, 0])
		// 	generateKeycap(keyId, isHomeKey, keyType);
        // }
        // if (keyCapIndex == 3)
        // {
        //     ySpacing = (Sum(columnKeyCapLengthsFromRow) - (currentKeyCapLength / 2)) + 2;
        //     translate([ xSpacing, ySpacing])
		// 	mjf_supports(size=keyParameters[keyType][keyId].bottomLength, gen_support=1, sprue_trim)
		// 	rotate([0, 0, is_undef(keyCap.rotate) ? 0 : keyCap.rotate])
        //     mirror([keyCap.mirror ? 1 : 0, 0, 0])
		// 	generateKeycap(keyId, isHomeKey, keyType);
        // }
        // if (keyCapIndex == 4)
        // {
        //     ySpacing = (Sum(columnKeyCapLengthsFromRow) - (currentKeyCapLength / 2)) -1;
        //     translate([ xSpacing, ySpacing])
		// 	mjf_supports(size=keyParameters[keyType][keyId].bottomLength, gen_support=1, sprue_trim)
		// 	rotate([0, 0, is_undef(keyCap.rotate) ? 0 : keyCap.rotate])
        //     mirror([keyCap.mirror ? 1 : 0, 0, 0])
		// 	generateKeycap(keyId, isHomeKey, keyType);
        // }
        // if (keyCapIndex == 5)
        // {
        //     ySpacing = Sum(columnKeyCapLengthsFromRow) - (currentKeyCapLength / 2) -1;
        //     translate([ xSpacing, ySpacing])
		// 	mjf_supports(size=keyParameters[keyType][keyId].bottomLength, gen_support=1, sprue_trim)
		// 	rotate([0, 0, is_undef(keyCap.rotate) ? 0 : keyCap.rotate])
        //     mirror([keyCap.mirror ? 1 : 0, 0, 0])
		// 	generateKeycap(keyId, isHomeKey, keyType);
        // }

 		
	}
}

module generateKeycap(keyId, isHomeKey, keyType)
{
	echo(keyId,isHomeKey, keyType);
	if (keyType == "Concave")
	{
		concave_keycap(keyID = keyId, // change profile refer to KeyParameters Struct
		       cutLen = 0,    // Don't change. for chopped caps
		       Stem = true,   // tusn on shell and stems
		       Dish = true,   // turn on dish cut
		       Stab = 0,
		       visualizeDish = false, // turn on debug visual of Dish
		       crossSection = false,  // center cut to check internal
		       homeDot = isHomeKey,   // turn on homedots
		       Legends = false);
	}
	else if (keyType == "Convex")
	{
		convex_keycap(keyID = keyId,
		              cutLen = 0,  // Don't change. for chopped caps
		              Stem = true, // turn on shell and stems
		              Dish = true, // turn on dish cut
		              Stab = 0,
		              visualizeDish = false, // turn on debug visual of Dish
		              crossSection = false,  // center cut to check internal
		              homeDot = isHomeKey,   // turn on homedots
		              Legends = false);
	}
	else if (keyType == "Thumb")
	{
		thumb_keycap(keyID = keyId,
		             cutLen = 0,  // Don't change. for chopped caps
		             Stem = true, // turn on shell and stems
		             Dish = true, // turn on dish cut
		             Stab = 0,
		             visualizeDish = false, // turn on debug visual of Dish
		             crossSection = false,  // center cut to check internal
		             homeDot = false,       // turn on homedots
		             Legends = false);
	}
}
