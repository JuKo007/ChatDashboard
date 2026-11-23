###################################################################################### SHINY SERVER UI #####

gesis_page_styles <- tagList(
  tags$link(rel = "stylesheet", href = "package/dist/gesis-web.css"),
  tags$link(rel = "stylesheet", href = "css/study.css")
)

study_columns <- function(...) tags$div(class = "study-columns", ...)
study_sidebar <- function(...) tags$aside(class = "study-sidebar", ...)
study_main <- function(...) tags$section(class = "study-main", ...)

gesis_footer <- includeHTML("www/gesis-footer.html")

# Define UI for ChatDashboard application
app_ui <- fluidPage(theme = shinytheme("flatly"),
                    
                    # Detecting browser for mobile optimization
                    shinybrowser::detect(),
                    
                    # keep session alive for locked phones
                    tags$head(tags$script(HTML("
                        setInterval(function(){
                          Shiny.setInputValue('keepalive', Date.now(), {priority:'event'});
                        }, 15000);
                      "))),
                    
                    # ensure users start at the top of a new page when changing tabs on mobile
                    tags$head(tags$script(HTML("
                      (function(){
                        function scrollTopNow(){
                          window.scrollTo(0,0);
                          document.body.scrollTop = 0;
                          document.documentElement.scrollTop = 0;
                          setTimeout(function(){ window.scrollTo(0,0); }, 0); // iOS
                        }
                        // Bootstrap tab change (navbarPage)
                        $(document).on('shown.bs.tab', 'a[data-toggle=\"tab\"]', scrollTopNow);
                        // Your custom microsite nav
                        $(document).on('click', '.gs-micro-nav a', function(){ setTimeout(scrollTopNow, 0); });
                        // After you rewire visible/active tabs
                        Shiny.addCustomMessageHandler('microNavVisible', function(){ setTimeout(scrollTopNow, 0); });
                      })();
                    "))),
                    
                    useShinyjs(),
                    useWaiter(),
                    tags$head(gesis_page_styles),
                    tags$div(class = "study-shell",

                    # GESIS micro header and banner
                    tags$div(id = "gesis-micro-header", includeHTML("www/gesis-micro-header.html")),
                    includeHTML("www/gesis-microsite-banner.html"),
                    
                    # GESIS microsite navigation controlling Shiny tabs (full width, dark)
                    tags$nav(class = "gs-micro-nav", `aria-label` = "Studiennavigation",
                             tags$ul(class = "list-inline",
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[3],  display_text[3]  )), # Überblick
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[15], display_text[15] )), # Daten hochladen
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[87], display_text[87] )), # Spender Auswahl
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[28], display_text[28] )), # Daten auswählen
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[46], display_text[46] )), # Ergebnisse
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[76], display_text[76] ))  # Impressum
                             )
                    ),
                    
                    # Click handler + active state
                    tags$script(HTML("
                    $(document).on('click','.gs-micro-nav a',function(e){
                      e.preventDefault();
                      $('.gs-micro-nav a').removeClass('is-active').removeAttr('aria-current');
                      $(this).addClass('is-active').attr('aria-current', 'page');
                      Shiny.setInputValue('go_tab', $(this).data('tab'), {priority:'event'});
                    });
                  ")),
                    
                    tags$script(HTML("
                      Shiny.addCustomMessageHandler('microNavVisible', function(msg){
                        var show = msg.show || [];
                        var active = msg.active || null;
                        $('.gs-micro-nav a').each(function(){
                          var $a = $(this), tab = $a.data('tab');
                          if (show.indexOf(tab) !== -1) { $a.closest('li').show(); }
                          else { $a.closest('li').hide(); }
                          $a.toggleClass('is-active', !!active && tab === active);
                          if (tab === active) $a.attr('aria-current', 'page');
                          else $a.removeAttr('aria-current');
                        });
                      });
                    ")),
                    
                                        ##################################### MAIN UI ####
                    
                    # Logo and App name in navbar page
                    navbarPage(title = tags$img(height = 35,
                                                width = 35,
                                                src = "WhatsR_logo.png"),
                               id = "ChatDashboard",
                               windowTitle = "ChatDashboard",
                               
                               ##################################### Overview Page ####
                               tabPanel(
                                 display_text[3],
                                 tags$section(
                                   class = "study-intro",
                                   tags$header(class = "study-intro-title", HTML(display_text[4])),
                                   tags$div(class = "study-prose", lang = landing_page_language,
                                            tags$p(HTML(display_text[5])),
                                            tags$p(HTML(display_text[6])),
                                            tags$p(HTML(display_text[7]))),
                                   tags$div(class = "callout",
                                            tags$strong("Wichtig"),
                                            tags$p("Lassen Sie diese Seite während der Datenspende geöffnet, damit Ihre Verbindung erhalten bleibt.")),
                                   actionButton("IntroCheck", display_text[14], class = "study-primary")
                                 )
                               ),

                               ##################################### DATA UPLOAD PAGE ####
                               tabPanel(display_text[15],
                                        
                                        # Sidebar
                                        study_columns(
                                          study_sidebar(h2(display_text[16],
                                                          align = "center"),
                                                       
                                                       tags$p("Wählen Sie Ihren WhatsApp-Export (.txt oder .zip)."),
                                                       tags$p("Sie können die Daten vor der Spende prüfen und auswählen."),
                                                       
                                                       # File selection field
                                                       div(class = "bs3-fileinput",
                                                           fileInput("file", label = "",
                                                                     accept = c(".txt", ".zip"),
                                                                     buttonLabel = display_text[20],
                                                                     placeholder = if (landing_page_language == "de") "Keine Datei ausgewählt" else "No file selected")
                                                       ),
                                                       
                                                       # Upload button
                                                       actionButton(inputId = "submit",
                                                                    label = display_text[21],
                                                                    class = "study-primary")
                                          ),
                                          
                                         
                                          #### MAIN PANEL 
                                          study_main(
                                            tags$div(class = "study-export-guide",
                                              
                                              # Heading + body text
                                              tags$h2("WhatsApp Chatverläufe exportieren"),
                                              tags$p(class = "study-prose", lang = "de", "Wenn Ihr Export schon vorliegt, können Sie die Datei direkt auswählen. Sonst öffnen Sie die Anleitung für Ihr Smartphone."),
                                              
                                              # ANDROID
                                              tags$details(
                                                tags$summary("Android"),
                                                tags$ol(
                                                  tags$li("Öffnen Sie WhatsApp auf Ihrem Smartphone und klicken Sie auf den Chat, dessen Verlauf Sie bereitstellen möchten."),
                                                  tags$li("Klicken Sie oben rechts im Chat auf die drei vertikalen Punkte."),
                                                  tags$li("Wählen Sie die Option `Mehr` im folgenden Menü aus."),
                                                  tags$li("Klicken Sie auf die Option `Chat exportieren`."),
                                                  tags$li("Im folgenden Fenster wählen Sie die Option `Ohne Medien` aus, falls eine Auswahl angezeigt wird."),
                                                  tags$li("Wählen Sie nun ein E-mail Programm aus der Liste aus. Es öffnet sich eine E-mail an welche der Chatverlauf automatisch angehängt ist."),
                                                  tags$li("Geben Sie in das Feld 'An' Ihre eigene E-mail Adresse ein und senden Sie die E-mail an sich selbst ab.")
                                                ),
                                                tags$img(src = "DataExport_Guide_Android.png",
                                                         style = "width:100%;height:auto;", alt = "Android export guide"),
                                                tags$ol(start = 8,
                                                  tags$li("Öffnen Sie das E-mail Postfach an welches Sie den Chatverlauf gerade geschickt haben."),
                                                  tags$li("Laden Sie den Anhang der E-mail herunter. Dies kann entweder eine .zip Datei oder eine .txt Datei sein."),
                                                  tags$li("Laden Sie den heruntergeladenen Chatverlauf im Fenster links (PC), bzw. oben (Smartphone,) auf diese Website hoch."),
                                                  tags$li("Auf der nächsten Seite erhalten Sie die Möglichkeit Ihren anonymisierten Chatverlauf nochmal einzusehen und anschließend abzuschicken.")
                                                )
                                              ),
                                              
                                              # iPHONE
                                              tags$details(
                                                tags$summary("iPhone"),
                                                tags$ol(
                                                  tags$li("Öffnen Sie WhatsApp auf Ihrem Smartphone und klicken Sie auf den Chat dessen Verlauf Sie bereitstellen möchten."),
                                                  tags$li("Klicken Sie oben in der Mitte des Chatfensters auf den Namen Ihres Chatpartners."),
                                                  tags$li("Scrollen Sie im Menü nach unten und wählen Sie die Option `Chat exportieren` aus"),
                                                  tags$li("Im folgenden Fenster wählen Sie die Option `Ohne Medien` aus, falls eine Auswahl angezeigt wird."),
                                                  tags$li("Wählen Sie nun ein E-mail Programm aus er Liste aus. Es öffnet sich eine E-mail an welche der Chatverlauf automatisch angehängt ist."),
                                                  tags$li("Geben Sie in das Feld 'An' Ihre eigene E-mail Adresse ein und senden Sie die E-mail an sich selbst ab.")
                                                ),
                                                tags$img(src = "WhatsApp_DataExport_iOS.png",
                                                         style = "width:100%;height:auto;", alt = "iOS export guide"),
                                                tags$ol(start = 7,
                                                  tags$li("Öffnen Sie das E-mail Postfach an welches Sie den Chatverlauf gerade geschickt haben."),
                                                  tags$li("Laden Sie den Anhang der E-mail herunter. Dies kann entweder eine .zip Datei oder eine .txt Datei sein."),
                                                  tags$li("Laden Sie den heruntergeladenen Chatverlauf im Fenster links (PC), bzw. oben (Smartphone,) auf diese Website hoch."),
                                                  tags$li("Auf der nächsten Seite erhalten Sie die Möglichkeit Ihren anonymisierten Chatverlauf nochmal einzusehen und anschließend abzuschicken.")
                                                )
                                              )
                                            )
                                          ),
                                          
                                          # End sidebar layout
                                        )
                                        
                                        # End tab panel
                               ),
                               
                               ##################################### PARTICIPANT - USER SELECTION PAGE ####
                               tabPanel(
                                 display_text[87],
                                 tags$section(
                                   class = "study-person-picker",
                                   tags$h2(if (landing_page_language == "de") "Wer sind Sie im Chat?" else "Who are you in the chat?"),
                                   tags$p(if (landing_page_language == "de") "Wählen Sie die Karte über Ihrem Namen aus." else "Select the card above your name."),
                                   tags$p(
                                     class = "study-person-privacy",
                                     if (landing_page_language == "de") "Ihr Anzeigename dient hier zur Orientierung. In der Datenspende wird nur Ihre Kennung verwendet, zum Beispiel „Person_1“." else "Your display name helps you identify your card. The donation uses only your alias, such as Person_1."
                                   ),
                                   uiOutput("person_cards"),
                                   shinyjs::disabled(
                                     actionButton("person_submit", if (landing_page_language == "de") "Weiter" else "Continue",
                                                  class = "study-primary")
                                   )
                                 )
                               ),

                               ##################################### DATA EXPLORATION PAGE ####
                               tabPanel(display_text[28],
                                        
                                        # Sidebar Panel
                                        study_sidebar(
                                          
                                          # Info text
                                          #h2(display_text[29], align = "center"),
                                          #HTML(display_text[30]),
                                          #HTML("<br><br>"),
                                          #HTML(display_text[31]),
                                          
                                          # column selection
                                          h3(display_text[32]),
                                          tags$p("Wählen Sie aus, welche Spalten Sie prüfen möchten. Grau markierte Spalten werden nicht gespendet."),
                                          pickerInput("show_vars",
                                                      display_text[34],
                                                      choices = c(""),
                                                      selected = c(""),
                                                      #label = display_text[35],
                                                      multiple = TRUE,
                                                      options  = pickerOptions(
                                                        selectedTextFormat = "count",
                                                        countSelectedText  = "{0} Spalten ausgewählt"#,
                                                        #mobile = TRUE
                                                      ),
                                                      choicesOpt = list(style = c("color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "background:lightgrey;color:black",
                                                                                  "background:lightgrey;color:black",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;"))),
                                          
                                          # Row selection
                                          h3(display_text[36]),
                                          tags$ol(
                                            tags$li("Markieren Sie die Zeilen in der Tabelle."),
                                            tags$li("Klicken Sie auf „Zeile(n) ausschließen“.")
                                          ),
                                          tags$p("„Zeilen wiederherstellen“ macht die Ausschlüsse rückgängig."),
                                          actionButton("excludeRows",display_text[38]),
                                          actionButton("RestoreRows",display_text[39]),
                                          
                                          # Data donation
                                          h3(display_text[40]),
                                          tags$p("Prüfen Sie Ihre Auswahl, bevor Sie die Spende bestätigen."),
                                          actionButton(inputId = "donation",
                                                       label = display_text[42],
                                                       class = "study-primary")
                                          
                                          # End sidebar panel
                                        ),
                                        
                                        # Main panel
                                        study_main(
                                          
                                          # Headline
                                          h1(display_text[43],align = "center"),
                                          
                                          # Dataframe
                                          tags$div(class = "study-donation-table", DTOutput("frame")),
                                          
                                          # Download buttons
                                          tags$div(class = "study-downloads",
                                                   downloadButton("downloadSelection", display_text[44]),
                                                   downloadButton("downloadData", display_text[45])),
                                          
                                          # End main panel
                                        )
                                        
                                        # End tab panel
                               ),
                               
                               ##################################### OVERALL RESULTS PAGE ####
                               tabPanel(display_text[46],
                                        
                                        tabsetPanel(id = "study-results-tabs", type = "tabs",
                                                    
                                                    ##################################### RESULTS: MESSAGES SUBPAGE ####
                                                    tabPanel(display_text[47],
                                                             
                                                             # sidebar panel
                                                             study_sidebar(h3(display_text[48], align = "center"),
                                                                          tags$p(display_text[49]),
                                                                          
                                                                          # Sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_msg",
                                                                                               "",
                                                                                               display_text[52]),
                                                                          
                                                                          # Time selection
                                                                          h3(display_text[53]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_messages",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56])
                                                                          
                                                                          # End sidebar panel
                                                             ),
                                                             
                                                             # Main Panel
                                                             study_main(
                                                               
                                                               # Plot 1
                                                               h1(display_text[57],align = "center"),
                                                               tags$div(class = "study-privacy", HTML(display_text[58])),
                                                               addSpinner(plotOutput("message1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 2
                                                               h1(display_text[59],align = "center"),
                                                               addSpinner(plotOutput("tokensbwah1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # plot 3
                                                               addSpinner(plotOutput("tokensbwah2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8")
                                                               
                                                               # End main panel
                                                             ),
                                                             
                                                             # end tab panel
                                                             width = 6, offset = 5),
                                                    
                                                    ##################################### RESULTS: LINKS SUBPAGE ####
                                                    tabPanel(display_text[60],
                                                             
                                                             # sidebar panel
                                                             study_sidebar(h3(display_text[48], align = "center"),
                                                                          tags$p(display_text[61]),
                                                                          
                                                                          # sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_links",
                                                                                               "",
                                                                                               display_text[62]),
                                                                          
                                                                          # timespan selection
                                                                          h3(display_text[55]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_links",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56]),
                                                                          
                                                                          # Link Minimum selection
                                                                          h3(display_text[63]),
                                                                          helpText(display_text[64]),
                                                                          sliderInput("LinkMinimum",
                                                                                      "",
                                                                                      min = 1,
                                                                                      max = 100,
                                                                                      value = 5)
                                                                          
                                                                          # End sidebar panel
                                                             ),
                                                             
                                                             # Main Panel
                                                             study_main(
                                                               
                                                               # Plot 1
                                                               h3(display_text[65], align = "center"),
                                                               tags$div(class = "study-privacy", HTML(display_text[58])),
                                                               addSpinner(plotOutput("links4",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # plot 2
                                                               addSpinner(plotOutput("links2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # plot 3
                                                               addSpinner(plotOutput("links1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                             ),
                                                             
                                                             width = 6, offset = 5),
                                                    
                                                    ##################################### RESULTS: SMILIES SUBPAGE ####
                                                    tabPanel(display_text[66],
                                                             
                                                             # sidebar panel
                                                             study_sidebar(h3(display_text[48], align = "center"),
                                                                          tags$p(display_text[67]),
                                                                          
                                                                          # sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_smilies",
                                                                                               "",
                                                                                               display_text[52]),
                                                                          
                                                                          # time range selection
                                                                          h3(display_text[53]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_smilies",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56]),
                                                                          
                                                                          # smilie minimum selection
                                                                          h3(display_text[63]),
                                                                          helpText(display_text[68]),
                                                                          sliderInput("SmilieMinimum",
                                                                                      "", min = 1,
                                                                                      max = 100,
                                                                                      value = 5)
                                                                          
                                                             ),
                                                             
                                                             # Main Panel
                                                             study_main(
                                                               
                                                               # Plot 1
                                                               h3(display_text[69], align = "center"),
                                                               tags$div(class = "study-privacy", HTML(display_text[58])),
                                                               addSpinner(plotOutput("smilies4",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 2
                                                               addSpinner(plotOutput("smilies2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 3
                                                               addSpinner(plotOutput("smilies1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # end main panel
                                                             ),
                                                             
                                                             # end tabpanel
                                                             width = 6, offset = 5),
                                                    
                                                    ##################################### RESULTS: EMOJI SUBPAGE ####
                                                    tabPanel(display_text[70],
                                                             
                                                             # sidebar panel
                                                             study_sidebar(h3(display_text[48], align = "center"),
                                                                          tags$p(display_text[71]),
                                                                          
                                                                          # sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_emoji",
                                                                                               "",
                                                                                               display_text[62]),
                                                                          
                                                                          # timeframe selection
                                                                          h3(display_text[53]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_emoji",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56]),
                                                                          
                                                                          # minimum emoji selection
                                                                          h3(display_text[63]),
                                                                          helpText(display_text[72]),
                                                                          sliderInput("EmojiMinimum",
                                                                                      "",
                                                                                      min = 1,
                                                                                      max = 100,
                                                                                      value = 50)
                                                                          
                                                                          
                                                                          # end sidebar panel
                                                             ),
                                                             
                                                             # Main Panel
                                                             study_main(
                                                               
                                                               # Plot 1
                                                               h3(display_text[73],
                                                                  align = "center"),
                                                               tags$div(class = "study-privacy", HTML(display_text[58])),
                                                               addSpinner(plotOutput("emoji4",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 2
                                                               addSpinner(plotOutput("emoji2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 3
                                                               addSpinner(plotOutput("emoji1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # end main panel
                                                             ),
                                                             
                                                             # end tabpanel
                                                             width = 6, offset = 5),
                                                    
                                                    
                                                    ##################################### RESULTS: REPLYTIMES SUBPAGE ####
                                                    tabPanel(display_text[74],
                                                             
                                                             # sidebar panel
                                                             study_sidebar(h3(display_text[48], align = "center"),
                                                                          
                                                                          tags$p(display_text[75]),
                                                                          
                                                                          # sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_replies",
                                                                                               "",
                                                                                               display_text[52]),
                                                                          
                                                                          # timeframe selection
                                                                          h3(display_text[53]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_replies",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56])
                                                                          
                                                                          
                                                             ),
                                                             
                                                             # Main Panel
                                                             study_main(
                                                               
                                                               # Plot 1
                                                               h3(display_text[74], align = "center"),
                                                               tags$div(class = "study-privacy", HTML(display_text[58])),
                                                               addSpinner(plotOutput("replytime1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 2
                                                               addSpinner(plotOutput("replytime2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8")
                                                               
                                                               # End main panel
                                                             ),
                                                             
                                                             # end tab panel
                                                             width = 6, offset = 5)
                                                    
                                                    
                                                    # End tabset panel
                                        )
                                        
                                        
                                        
                                        # End tab Panel
                               ),
                               
                               ##################################### RESULTS: IMPRESSUM PAGE ####
                               tabPanel(display_text[76],
                                        tags$section(class = "study-contact",
                                                     tags$h2(display_text[76]),
                                                     HTML(display_text[77])))
                               
                               # End navbarpage
                    ),
                    
                    gesis_footer
                    )
)

###################################################################################### SECURING APP WITH SHINYMANAGER #####

# Let shinymanager build the login form, then add branding around its card.
secure_ui <- shinymanager::secure_app(
  app_ui,
  language = landing_page_language,
  head_auth = gesis_page_styles
)

gesis_login_header <- tags$header(
  class = "gesis-login-header",
  tags$div(id = "gesis-micro-header", includeHTML("www/gesis-micro-header.html")),
  includeHTML("www/gesis-microsite-banner.html")
)

ui <- function(request) {
  page <- secure_ui(request)
  login <- htmltools::tagQuery(page)$find("#auth-auth-mod.panel-auth")
  if (login$length() == 0) return(page)

  login$
    addClass("gesis-login")$
    prepend(gesis_login_header)$
    append(gesis_footer)$
    allTags()
}







