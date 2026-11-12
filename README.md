# T-cell transmigration image analysis

This project contains two Fiji/ImageJ macros for counting bright fluorescent dots in a folder of images. You do not need programming experience to run them. The settings to change are grouped at the top of each macro, and the macros create images that let you check what was counted.

## Choose the right macro

| Macro | Choose this when | What it counts |
| --- | --- | --- |
| `scripts/spot_detection.ijm` | The target looks like a small, bright point. | Bright peaks in the image. It is best when the peak location and intensity matter. |
| `scripts/particle_detection.ijm` | The target has a visible area or outline. | Segmented objects. It is best when object area, shape, and intensity matter. |

Use one macro at a time and use a separate output folder for each analysis. The two macros create some files with the same names, so using one shared output folder can overwrite earlier results.

## What you need

1. Fiji installed on your computer. Download it from [fiji.sc](https://fiji.sc/) if needed.
2. Images saved as `.tif`, `.tiff`, `.png`, or `.jpg` with lowercase file extensions.
3. An input folder containing only the images you want to analyse for that run.
4. The target fluorescence in the image or channel that will be processed. The macros do not choose a channel for you, so prepare a single-channel image first when working with multichannel data.

`particle_detection.ijm` uses Fiji's built-in **Auto Local Threshold** command. Standard Fiji installations include it.

## Set up your folders

The `data/` and `output/` folders are deliberately empty in the shared project. Put your raw images under `data/` and save analysis results under `output/`. These files are ignored by Git, so they will not be included when the code is shared on GitHub.

For example, use a matching input and output folder for each experiment:

```text
data/
  experiment_2026_11_12/
output/
  experiment_2026_11_12_spot/
  experiment_2026_11_12_particle/
scripts/
```

The macros only look at images directly inside the selected input folder. They do not search inside subfolders.

## Run a macro

1. Start with a small test set of representative images. Include clear targets, faint targets, and background-only images if available.
2. Open either file in Fiji: `scripts/spot_detection.ijm` or `scripts/particle_detection.ijm`. If needed, use **Plugins > Macros > Edit...** to open the file in Fiji's macro editor.
3. At the top of the macro, find the two lines beginning with `inputDir` and `outputDir`. Replace the text between quotation marks with your input and output folder locations.
4. Keep the final `/` in both folder locations. The macro needs it to find and save files correctly.
5. Change detection settings only after choosing the macro and folder locations. The next sections explain each setting.
6. Click **Run** in the macro editor. Fiji works in batch mode, so it may not display every image while it runs.
7. Open the verification images in the output folder. Only use the CSV counts after checking that the yellow markers or outlines match the objects you intended to count.

For example, the two folder settings can look like this:

```ijm
inputDir  = "/full/path/to/project/data/experiment_2026_11_12/";
outputDir = "/full/path/to/project/output/experiment_2026_11_12_spot/";
```

The checked-in macros currently contain paths for the pilot dataset. Change these paths for another computer or experiment. Leave `scriptDir` and `projectDir` unchanged.

## Use `spot_detection.ijm` for point-like spots

This macro makes a blurred copy of each image to find bright peaks, then measures the corresponding points on the unblurred image. Each detected spot is marked in yellow in a verification TIFF.

### Settings to adjust

| Setting | Default | Plain-language meaning | When to change it |
| --- | ---: | --- | --- |
| `inputDir` | Pilot-data folder | Where Fiji reads your images. | Change for every experiment. |
| `outputDir` | Pilot-output folder | Where Fiji saves results. | Change for every experiment or analysis method. |
| `sigmaVal` | `1.5` px | How strongly the image is smoothed before peaks are found. | Increase if grainy noise creates many false spots. Decrease if nearby real spots are being merged or missed. |
| `promVal` | `26` | How much brighter a point must be than its surroundings before it is counted. | Increase to count only clear, strong spots. Decrease to include fainter spots, then inspect carefully for false positives. |

### Files created

| File | What it contains |
| --- | --- |
| `Individual_Dot_Intensities.csv` | One row per detected spot, including mean and maximum intensity, image name, and spot number. |
| `Total_Counts_Summary.csv` | One total spot count per image. |
| `Verification_Images/<image>_verified.tif` | The source image with each counted spot marked in yellow. |

## Use `particle_detection.ijm` for outlined objects

This macro removes uneven background, separates foreground objects from background, and then keeps objects that meet your size, shape, and brightness rules. It saves each accepted object as an ROI and draws a yellow outline in the verification TIFF.

### Settings to adjust

| Setting | Default | Plain-language meaning | When to change it |
| --- | ---: | --- | --- |
| `inputDir` | Pilot-data folder | Where Fiji reads your images. | Change for every experiment. |
| `outputDir` | Pilot-output folder | Where Fiji saves results. | Change for every experiment or analysis method. |
| `sigmaVal` | `1.5` px | Smoothing before objects are separated from background. | Increase if pixel-scale noise creates fragmented objects. Decrease if smoothing merges neighbouring objects. |
| `rollingBall` | `20` px | The size of background variation that Fiji removes. | Start with a value larger than the widest real dot. Increase for broader uneven background, but check that real signal is not removed. |
| `localRadius` | `15` px | The neighbourhood Fiji uses to decide what is local background. | Increase for more slowly varying background. Decrease when background changes over short distances. |
| `localContrast` | `15` | How different an object must be from its nearby background. | Increase to ignore dim or low-contrast noise. Decrease to retain weak objects. Values of `25` to `40` give stricter filtering, as noted in the macro. |
| `minSize` | `10` | Smallest allowed object area. | Increase to remove small specks. This is usually in px^2, but uses calibrated area units if the image has a spatial calibration. |
| `maxSize` | `"Infinity"` | Largest allowed object area. | Keep `"Infinity"` when there is no upper limit, or use a number to reject large debris and merged objects. |
| `minCirc` | `0.55` | How round an object must be. `1` means perfectly circular. | Increase to reject elongated or irregular objects. |
| `minBrightness` | `10` | Lowest permitted mean intensity on the original image. | Set to `0` to turn this filter off. Raise it to remove dim false positives. Use values appropriate for your image bit depth. |
| `outlinePx` | `2` px | Thickness of yellow outlines in verification images. | Change only to make the visual check easier; it does not affect results. |

Brightness values depend on how images were acquired. An 8-bit image ranges from 0 to 255, while 16-bit images can have much larger values. Do not reuse `minBrightness` blindly after changing exposure, microscope settings, staining, or image type.

### Files created

| File | What it contains |
| --- | --- |
| `Individual_Dot_Measurements.csv` | One row per accepted object, including area, intensity, shape measurements, image name, and object number. |
| `Total_Counts_Summary.csv` | One total accepted-object count per image. |
| `Saved_ROIs/<image>_RoiSet.zip` | The saved Fiji regions of interest for accepted objects. |
| `Verification_Images/<image>_verified.tif` | The source image with each accepted object outlined in yellow. |

## A reliable tuning workflow

1. Choose a small, representative test set before analysing a full experiment.
2. Run the macro with the default settings and inspect the yellow verification markings.
3. Change one setting at a time and rerun the same test images.
4. For spot detection, adjust `sigmaVal` first and `promVal` second.
5. For particle detection, adjust background and threshold settings first (`sigmaVal`, `rollingBall`, `localRadius`, `localContrast`), then size and shape (`minSize`, `maxSize`, `minCirc`), then brightness (`minBrightness`).
6. Record the final settings in your lab notes or analysis record. Recheck them whenever magnification, pixel size, exposure, staining, or background changes.
7. Keep verification TIFFs and ROI ZIP files with the CSV results so the counts can be checked later.

## If results do not look right

| Observation | First things to check |
| --- | --- |
| No images are processed | Check `inputDir`, the final `/`, and that images are directly in that folder with a supported lowercase extension. |
| Too many spots or objects | Increase `promVal` for spot detection. For particle detection, increase `localContrast`, `minSize`, `minCirc`, or `minBrightness` as appropriate. |
| Real spots or objects are missed | Decrease `promVal` for spot detection. For particle detection, decrease `localContrast`, `minSize`, `minCirc`, or `minBrightness` as appropriate. |
| Objects merge together | Reduce `sigmaVal`; then review `rollingBall`, `localRadius`, and threshold settings for particle detection. |
| CSV values differ from expected area units | Check whether the image has a spatial calibration; this changes the area units used by particle detection. |
