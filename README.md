<a href="https://deepwiki.com/baer842/your_schedule"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>

<img src="https://raw.githubusercontent.com/Lasslos/your_schedule/main/assets/school_blue.png" alt="Icon" width="256">
# EigenPlan for Untis

EigenPlan is a third-party mobile client for the Untis timetable.

<a href="https://play.google.com/store/apps/details?id=eu.laslo_hauschild.your_schedule&utm_source=github&utm_campaign=badge"><img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="80"/></a>
<a href="https://apt.izzysoft.de/fdroid/index/apk/eu.laslo_hauschild.your_schedule"><img alt="Get it on IzzyOnDroid" src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroid.png" height="80"/></a>

## Features

EigenPlan reads the timetable from the Untis API and displays it to you - customizable.

- Filter by class - No need to look endlessly for your classes, as only your classes are displayed.
- Change color of classes - Capture everything with a quick glance - Due to customizable colors.

## Screenshots

| <img src="https://raw.githubusercontent.com/Lasslos/your_schedule/main/assets/store_listing/screenshots/1.jpg" alt="Screenshot 1"> | <img src="https://raw.githubusercontent.com/Lasslos/your_schedule/main/assets/store_listing/screenshots/2.jpg" alt="Screenshot 2"> | <img src="https://raw.githubusercontent.com/Lasslos/your_schedule/main/assets/store_listing/screenshots/3.jpg" alt="Screenshot 3"> |
|------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| <img src="https://raw.githubusercontent.com/Lasslos/your_schedule/main/assets/store_listing/screenshots/4.jpg" alt="Screenshot 4"> | <img src="https://raw.githubusercontent.com/Lasslos/your_schedule/main/assets/store_listing/screenshots/5.jpg" alt="Screenshot 5"> | <img src="https://raw.githubusercontent.com/Lasslos/your_schedule/main/assets/store_listing/screenshots/6.jpg" alt="Screenshot 6"> |

## Documentation

I documented the whole process in my high school research paper, which you can find on
my [website](https://untis-connect.laslo-hauschild.eu/Facharbeit.pdf).
Note that this document is in German. Basically, I reverse-engineered the Untis API with HTTP-Toolkit and wrote a
Flutter app to display the data.

## Testing

If your school uses Untis and doesn't provide individual credentials, I'd be glad to support you to get the app running
for you school as well!
It should, in theory, already work, but you never know. If you need credentials to test the app yourself, please contact
me.

Pull requests and issues are always welcome.

### Code generation

Generate the nessessary code:
```shell
dart run build_runner build
```
