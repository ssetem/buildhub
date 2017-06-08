module Main exposing (..)

import Kinto
import Model exposing (..)
import Navigation exposing (..)
import Types exposing (..)
import Url exposing (..)
import View exposing (..)


main : Program Never Model Msg
main =
    Navigation.program
        UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


updateFilters : NewFilter -> Filters -> Filters
updateFilters newFilter filters =
    case newFilter of
        ClearAll ->
            initFilters

        NewProductFilter value ->
            { filters | product = value }

        NewVersionFilter value ->
            { filters | version = value }

        NewPlatformFilter value ->
            { filters | platform = value }

        NewChannelFilter value ->
            { filters | channel = value }

        NewLocaleFilter value ->
            { filters | locale = value }

        NewBuildIdSearch value ->
            { filters | buildId = value }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ filters, filterValues, settings } as model) =
    case msg of
        BuildRecordsFetched (Ok buildsPager) ->
            { model
                | buildsPager = buildsPager
                , loading = False
                , error = Nothing
            }
                ! [ getFilterFacets filters settings.pageSize 1 ]

        BuildRecordsFetched (Err err) ->
            { model | error = Just (toString err), loading = False } ! []

        LoadNextPage ->
            { model | page = model.page + 1 }
                ! [ getFilterFacets filters settings.pageSize (model.page + 1) ]

        LoadPreviousPage ->
            { model | page = model.page - 1 }
                ! [ getFilterFacets filters settings.pageSize (model.page - 1) ]

        BuildRecordsNextPageFetched (Ok buildsPager) ->
            { model
                | buildsPager = Kinto.updatePager buildsPager model.buildsPager
                , loading = False
                , error = Nothing
            }
                ! [ getFilterFacets filters settings.pageSize 1 ]

        BuildRecordsNextPageFetched (Err err) ->
            { model | error = Just (toString err), loading = False } ! []

        FacetsReceived (Ok facets) ->
            { model | facets = Just facets } ! []

        FacetsReceived (Err error) ->
            { model | error = Just (toString error) } ! []

        UpdateFilter newFilter ->
            let
                updatedFilters =
                    updateFilters newFilter filters
            in
                { model | filters = updatedFilters } ! [ getFilterFacets updatedFilters settings.pageSize 1 ]

        SubmitFilters ->
            let
                route =
                    routeFromFilters filters
            in
                { model | route = route, loading = True, error = Nothing }
                    ! [ getFilterFacets filters settings.pageSize 1, newUrl <| urlFromRoute route ]

        UrlChange location ->
            let
                updatedModel =
                    routeFromUrl model location
            in
                { updatedModel | loading = True, error = Nothing }
                    ! [ getBuildRecordList updatedModel ]

        DismissError ->
            { model | error = Nothing } ! []

        NewPageSize sizeStr ->
            let
                modelSettings =
                    model.settings

                updatedSettings =
                    { modelSettings | pageSize = Result.withDefault 100 <| String.toInt sizeStr }

                updatedModel =
                    { model | settings = updatedSettings, loading = True }
            in
                updatedModel ! [ getBuildRecordList updatedModel ]
