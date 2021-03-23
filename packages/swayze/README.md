<p align="center">
  <a href="https://rows.com">
  <br />
  <img src="https://rows.com/media/logo.svg" alt="Rows" width="150"/>
  <br />

  </a>
</p>

<p align="center">
<sub><strong>The spreadsheet with superpowers ✨!</strong></sub>
<br />
<br />
</p>

<p align="center">
  <a title="Pub" href="https://pub.dev/packages/swayze" ><img src="https://img.shields.io/pub/v/swayze.svg?style=popout" /></a>
  <a title="Rows lint" href="https://pub.dev/packages/rows_lint" ><img src="https://img.shields.io/badge/Styled%20by-Rows-754F6C?style=popout" /></a>
</p>


---


# Swayze 🕺

A set of widgets and controllers to display very large tables on flutter apps.

It exports a sliver that renders a table with scroll virtualization in two axis.
This means that only visible widgets are built, only the visible render objects go trough 
layout and painting.

Swayze is the spreadsheet rendering engine for tables in the [Rows app](https://rows.com/download).

## Installation

```
flutter pub add swayze
```


## Usage 

Everything on Swayze starts via a widget. `SliverSwayzeTable` represents a single table.

Since it is a sliver, it should be wrapped in a scroll view.  


```dart
CustomScrollView(
  slivers: [
      SliverSwayzeTable(
        tableData: widget.table,
        eventInterceptor: eventInterceptor,
        controller: controller,
        style: myStyle,
        // ...
      ),
  ],
);
```

### Style

The field `style` is optional and defaults to a default style instance `defaultSwayzeStyle`. 
It is possible to extends a style  just with the fields to be customized.

```dart
final myStyle = SwayzeStyle.defaultSwayzeStyle.copyWith(
  selectionStyle: SelectionStyle(color: Colors.pink),
);
```
