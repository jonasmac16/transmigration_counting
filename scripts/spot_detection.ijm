// =========================================================================
// 1. RESOLVE PATHS RELATIVE TO THIS MACRO FILE
// =========================================================================
macroPath = getInfo("macro.filepath");

if (macroPath == "") {
    exit("Error: Please save this macro as a .ijm file on disk before running it.");
}

// Get relative path
scriptDir  = File.getParent(macroPath);
projectDir = File.getParent(scriptDir) + File.separator;
inputDir   = "/home/jonas/projects/05_Tcell_transmigration/data/01_pilot/"; //projectDir + "data/01_pilot/";
outputDir  = "/home/jonas/projects/05_Tcell_transmigration/output/01_pilot/"; //projectDir + "output/01_pilot/";


sigmaVal = 1.5;   // Gaussian Blur radius in pixels
promVal  = 26;   // Find Maxima prominence
// =========================================================================


// Create output directory and verification subfolder automatically if they don't exist
if (!File.exists(outputDir)) File.makeDirectory(outputDir);
verifyDir = outputDir + "Verification_Images/";
if (!File.exists(verifyDir)) File.makeDirectory(verifyDir);

setBatchMode(true);
list = getFileList(inputDir);

// Clear previous tables and configure measurements to capture pixel intensity
run("Clear Results");
run("Set Measurements...", "mean max redirect=None decimal=2");

// Prepare a custom table for the summary counts per image
summaryTable = "Summary_Counts";
Table.create(summaryTable);
summaryRow = 0;

// Loop through all image files in the input folder
for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff") || endsWith(list[i], ".png") || endsWith(list[i], ".jpg")) {
        
        open(inputDir + list[i]);
        title = getTitle();
        baseName = File.nameWithoutExtension;
        
        // Convert to 16-bit grayscale and duplicate so we measure RAW intensities
        run("16-bit");
        rename("Raw_Image");
        run("Duplicate...", "title=Blurred_Image");
        
        // Apply Gaussian Blur ONLY to the duplicate
        run("Gaussian Blur...", "sigma=" + sigmaVal);
        
        // Find Maxima as a Point Selection
        run("Find Maxima...", "prominence=" + promVal + " output=[Point Selection]");
        
        startRow = nResults;
        
        // Transfer detected points back onto unblurred Raw_Image
        selectWindow("Raw_Image");
        run("Restore Selection");
        
        if (selectionType() == 10) {
            run("Measure");
            endRow = nResults;
            dotCount = endRow - startRow;
            
            for (r = startRow; r < endRow; r++) {
                setResult("Image_Name", r, title);
                setResult("Dot_ID", r, (r - startRow) + 1);
            }
            
            // Create and save Verification Image with yellow markers
            run("Duplicate...", "title=Verify");
            run("RGB Color");
            run("Restore Selection");
            setForegroundColor(255, 255, 0);
            run("Draw", "slice");
            saveAs("Tiff", verifyDir + baseName + "_verified.tif");
            close("Verify");
            
        } else {
            dotCount = 0;
        }
        
        // Log total count into Summary table
        Table.set("Image_Name", summaryRow, title, summaryTable);
        Table.set("Total_Dot_Count", summaryRow, dotCount, summaryTable);
        summaryRow++;
        
        close("Raw_Image");
        close("Blurred_Image");
    }
}

// Save both CSV files
updateResults();
saveAs("Results", outputDir + "Individual_Dot_Intensities.csv");
Table.save(outputDir + "Total_Counts_Summary.csv", summaryTable);

setBatchMode(false);
print("Done! Saved CSVs and Verification Images to: " + outputDir);
