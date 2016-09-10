class ZCL_ALV_TOOL definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF ty_hierarchy,
             id TYPE char18,
             level TYPE int4,
             description TYPE BEZEI40,
         END OF ty_hierarchy .
  types:
    tt_hierarchy TYPE STANDARD TABLE OF ty_hierarchy WITH KEY id .
  types:
    BEGIN OF ty_displayed_node,
         id   TYPE char18,
         text TYPE char40,
       END OF ty_displayed_node .

  methods DRAW_TREE
    importing
      !IT_HIERARCHY type TT_HIERARCHY .
  methods GET_FIELDCAT_BY_DATA
    importing
      !IS_DATA type ANY
    returning
      value(RT_FIELDCAT) type LVC_T_FCAT .
  methods GET_CONTAINER
    importing
      !IV_CONTAINER_NAME type CHAR30
    returning
      value(RO_CONTAINER) type ref to CL_GUI_CUSTOM_CONTAINER .
  methods GET_TREE
    importing
      !IO_CONTAINER type ref to CL_GUI_CUSTOM_CONTAINER
    returning
      value(RO_TREE) type ref to CL_GUI_ALV_TREE .
  methods GET_TEST_DATA
    returning
      value(RT_TEST_DATA) type TT_HIERARCHY .
protected section.
private section.

  types:
    BEGIN OF ty_node_relation,
            node_id TYPE char18,
            node_level TYPE int4," current level of node_id
            parent TYPE char18,
         END OF ty_node_relation .
  types:
    tt_node_relation TYPE STANDARD TABLE OF ty_node_relation WITH KEY node_id .
  types:
    BEGIN OF ty_tree_key,
             node_id TYPE char18,
             tree_key TYPE lvc_nkey,
         END OF ty_tree_key .
  types:
    tt_tree_key TYPE STANDARD TABLE OF ty_tree_key WITH KEY node_id .

  data MT_NODE_RELATION type TT_NODE_RELATION .
  data MO_TREE type ref to CL_GUI_ALV_TREE .

  methods RENDER_TREE .
  methods BUILD_NODE_RELATION
    importing
      !IT_HIERARCHY type TT_HIERARCHY .
ENDCLASS.



CLASS ZCL_ALV_TOOL IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_ALV_TOOL->BUILD_NODE_RELATION
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_HIERARCHY                   TYPE        TT_HIERARCHY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method BUILD_NODE_RELATION.

  data: ls_map TYPE ty_node_relation,
        lv_parent_found TYPE abap_bool.

  ls_map = value #( node_id = 'ROOT' node_level = 0 parent = 'ROOT'  ).
  APPEND ls_map TO mt_node_relation.

  LOOP AT it_hierarchy ASSIGNING FIELD-SYMBOL(<data>).
     lv_parent_found = abap_false.
   LOOP AT mt_node_relation ASSIGNING FIELD-SYMBOL(<Node>) WHERE node_level = <data>-level - 1.
      IF <data>-id CS <node>-node_id.
        ls_map = value #( node_id = <data>-id node_level = <data>-level parent = <node>-node_id ).
        APPEND ls_map to mt_node_relation.
        lv_parent_found = abap_true.
        EXIT.
      ENDIF.
   ENDLOOP.
   IF lv_parent_found = abap_false.
      ls_map = value #( node_id = <data>-id node_level = 1 parent = 'ROOT'  ).
      APPEND ls_map TO mt_node_relation.
   ENDIF.
  ENDLOOP.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ALV_TOOL->DRAW_TREE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_HIERARCHY                   TYPE        TT_HIERARCHY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD draw_tree.
    build_node_relation( it_hierarchy ).
    render_tree( ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ALV_TOOL->GET_CONTAINER
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_CONTAINER_NAME              TYPE        CHAR30
* | [<-()] RO_CONTAINER                   TYPE REF TO CL_GUI_CUSTOM_CONTAINER
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_CONTAINER.
    CREATE OBJECT ro_container
    EXPORTING
      container_name              = iv_container_name
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'(100).
  ENDIF.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ALV_TOOL->GET_FIELDCAT_BY_DATA
* +-------------------------------------------------------------------------------------------------+
* | [--->] IS_DATA                        TYPE        ANY
* | [<-()] RT_FIELDCAT                    TYPE        LVC_T_FCAT
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_fieldcat_by_data.
    DATA: lobj_stdesc TYPE REF TO cl_abap_structdescr,
          lv_stname   TYPE dd02l-tabname,
          lw_fields   TYPE LINE OF cl_abap_structdescr=>included_view,
          lw_fldcat   TYPE LINE OF lvc_t_fcat,
          lw_desc     TYPE x030l,
          lt_fields   TYPE cl_abap_structdescr=>included_view.
    lobj_stdesc ?= cl_abap_structdescr=>describe_by_data( is_data ).

    IF lobj_stdesc->is_ddic_type( ) IS NOT INITIAL.
      lv_stname = lobj_stdesc->get_relative_name( ).
      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_buffer_active        = space
          i_structure_name       = lv_stname
          i_bypassing_buffer     = 'X'
        CHANGING
          ct_fieldcat            = rt_fieldcat
        EXCEPTIONS
          inconsistent_interface = 1
          program_error          = 2
          OTHERS                 = 3.
      RETURN.
    ENDIF.

    lt_fields = lobj_stdesc->get_included_view( ).

    LOOP AT lt_fields INTO lw_fields.
      CLEAR: lw_fldcat,
             lw_desc.
      lw_fldcat-col_pos   = sy-tabix.
      lw_fldcat-fieldname = lw_fields-name.
      IF lw_fields-type->is_ddic_type( ) IS NOT INITIAL.
        lw_desc            = lw_fields-type->get_ddic_header( ).
        lw_fldcat-rollname = lw_desc-tabname.
      ELSE.
        lw_fldcat-inttype  = lw_fields-type->type_kind.
        lw_fldcat-intlen   = lw_fields-type->length.
        lw_fldcat-decimals = lw_fields-type->decimals.
      ENDIF.
      APPEND lw_fldcat TO rt_fieldcat.
    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ALV_TOOL->GET_TEST_DATA
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RT_TEST_DATA                   TYPE        TT_HIERARCHY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_TEST_DATA.
    data(ls_node) = value ty_hierarchy( id = '00001' level = 1 description = 'Level 1 a').
  APPEND ls_node TO rt_test_Data.
  ls_node = value ty_hierarchy( id = '00002' level = 1 description = 'Level 1 b').
  APPEND ls_node TO rt_test_Data.
  ls_node = value ty_hierarchy( id = '0000100002' level = 2 description = 'Level 2 a').
  APPEND ls_node TO rt_test_Data.
  ls_node = value ty_hierarchy( id = '0000100003' level = 2 description = 'Level 2 b').
  APPEND ls_node TO rt_test_Data.
  ls_node = value ty_hierarchy( id = '0000200003' level = 2 description = 'Level 2 b1').
  APPEND ls_node TO rt_test_Data.
  ls_node = value ty_hierarchy( id = '0000100004' level = 2 description = 'Level 2 c').
  APPEND ls_node TO rt_test_Data.
  ls_node = value ty_hierarchy( id = '000010000300000003' level = 3 description = 'Level 3 a').
  APPEND ls_node TO rt_test_Data.
  ls_node = value ty_hierarchy( id = '000020000300000003' level = 3 description = 'Level 3 b').
  APPEND ls_node TO rt_test_Data.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ALV_TOOL->GET_TREE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_CONTAINER                   TYPE REF TO CL_GUI_CUSTOM_CONTAINER
* | [<-()] RO_TREE                        TYPE REF TO CL_GUI_ALV_TREE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_TREE.
     CREATE OBJECT ro_tree
    EXPORTING
      parent                      = io_container
      node_selection_mode         = cl_gui_column_tree=>node_sel_mode_single
      item_selection              = 'X'
      no_html_header              = 'X'
      no_toolbar                  = ''
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      illegal_node_selection_mode = 5
      failed                      = 6
      illegal_column_name         = 7.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.                          "#EC NOTEXT
  ENDIF.

  mo_tree = ro_tree.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_ALV_TOOL->RENDER_TREE
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method RENDER_TREE.
    DATA: p_relat_key TYPE lvc_nkey,
        p_node_key  TYPE lvc_nkey,
        lt_tree_key TYPE tt_tree_key,
        ls_displayed TYPE ty_displayed_node.
    CALL METHOD mo_tree->add_node
    EXPORTING
      i_relat_node_key = p_relat_key
      i_relationship   = cl_gui_column_tree=>relat_last_child
      i_node_text      = 'Hierarchy'
    IMPORTING
      e_new_node_key   = p_node_key.

    data(ls_tree_key) = value ty_tree_key( node_id = 'ROOT' tree_key = p_node_key ).
    APPEND ls_tree_key TO lt_tree_key.

  "delete lt_node index 1.
  LOOP AT mt_node_relation ASSIGNING FIELD-SYMBOL(<node1>).
    ls_displayed-id = <node1>-node_id.
    ls_displayed-text = <node1>-node_level.
    READ TABLE lt_tree_key ASSIGNING FIELD-SYMBOL(<parent>) WITH KEY node_id = <node1>-parent.
    CALL METHOD mo_tree->add_node
    EXPORTING
      i_relat_node_key = <parent>-tree_key
      i_relationship   = cl_gui_column_tree=>relat_last_child
      i_node_text      = conv #( <Node1>-node_id )
      is_outtab_line   = ls_displayed
    IMPORTING
      e_new_node_key   = p_relat_key.

    ls_tree_key = value #( node_id = <node1>-node_id tree_key = p_relat_key ).
    APPEND ls_tree_key TO lt_tree_key.
  ENDLOOP.
  endmethod.
ENDCLASS.