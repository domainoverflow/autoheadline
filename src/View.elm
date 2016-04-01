module View (..) where

import String
import State exposing (graphFromNews)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Signal exposing (..)
import Dict
import Set
import Markov
import Types exposing (..)


rootView : Address Action -> Model -> Html
rootView uiChannel model =
  div
    [ class "container" ]
    [ div
        [ class "row" ]
        [ div
            [ class "col-xs-12" ]
            [ body uiChannel model ]
        ]
    ]


itemView : NewsItem -> Html
itemView item =
  div [] [ text item.title ]


tokenButton : Address Action -> ( String, Int ) -> Html
tokenButton uiChannel ( token, linkCount ) =
  let
    buttonType =
      if linkCount <= 1 then
        "btn-default"
      else if linkCount <= 3 then
        "btn-info"
      else if linkCount <= 6 then
        "btn-warning"
      else
        "btn-danger"
  in
    button
      [ classList
          [ ( "btn", True )
          , ( buttonType, True )
          ]
      , onClick uiChannel (ChooseToken token)
      ]
      [ text token
      , text " "
      ]


tokenButtons : Address Action -> List ( String, Int ) -> Html
tokenButtons uiChannel weightedTokens =
  div
    []
    (List.map
      (tokenButton uiChannel)
      weightedTokens
    )


body : Address Action -> Model -> Html
body uiChannel model =
  div
    []
    [ div
        [ class "row" ]
        [ div
            [ class "col-xs-12 col-sm-8 col-sm-offset-2" ]
            [ h1
                []
                [ text "Make Your Own HackerNews Headline" ]
            , h2
                []
                [ text " from the latest 200 stories." ]
            ]
        , div
            [ class "col-xs-12 col-sm-2" ]
            [ h4
                []
                [ a
                    [ href "https://github.com/krisajenkins/autoheadline" ]
                    [ text "See the source code" ]
                ]
            ]
        ]
    , div
        [ class "row" ]
        [ div
            [ class "col-xs-12 col-sm-8 col-sm-offset-2" ]
            [ blockquote
                []
                [ h3 [] [ text <| String.join " " model.phrase ] ]
            ]
        ]
    , case model.newsItems of
        Just (Ok items) ->
          newsBody uiChannel model.phrase items

        Just (Err err) ->
          div
            [ class "alert alert-danger" ]
            [ text (toString err) ]

        _ ->
          loading
    ]


newsBody : Address Action -> List String -> List NewsItem -> Html
newsBody uiChannel currentPhrase newsItems =
  let
    currentToken =
      Maybe.withDefault
        Markov.startToken
        (List.head (List.reverse currentPhrase))

    graph =
      graphFromNews newsItems

    nextTokens =
      Dict.get currentToken graph

    weighToken token =
      ( token
      , List.length ((Set.toList (Maybe.withDefault Set.empty (Dict.get token graph))))
      )
  in
    div
      []
      [ div
          [ class "row" ]
          [ div
              [ class "col-xs-12 col-sm-2 well" ]
              [ text "Click any button to choose the next word." ]
          , div
              [ class "col-xs-12 col-sm-8" ]
              [ case nextTokens of
                  Nothing ->
                    div [] []

                  Just tokens ->
                    let
                      weightedTokens =
                        List.map weighToken (Set.toList tokens)
                    in
                      tokenButtons uiChannel weightedTokens
              ]
          , div
              [ class "col-xs-12 col-sm-2" ]
              [ button
                  [ class "btn btn-warning"
                  , onClick uiChannel Reset
                  ]
                  [ text "Reset!" ]
              ]
          ]
      , div
          [ class "row" ]
          [ div
              [ class "col-xs-12 col-sm-8 col-sm-offset-2" ]
              [ div [] (List.map itemView newsItems) ]
          ]
      ]


loading : Html
loading =
  div
    [ class "loading" ]
    [ img
        [ src "loading_wheel.gif"
        , class "loading"
        ]
        []
    ]
