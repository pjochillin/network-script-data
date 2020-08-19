Repository_DCommand:
    type: task
    PermissionRoles:
    - Everyone
    definitions: Message|Channel|Author|Group
    debug: false
    Context: Color
    script:
# - ██ [ Clean Definitions & Inject Dependencies ] ██
    # - inject Role_Verification
    - define color Code
    - inject Embedded_Color_Formatting
    - define Hook <script[DDTBCTY].data_key[WebHooks.<[Channel]>.hook]>
    - define Headers <list[User-Agent/really|Content-Type/application/json]>

    - define Data <yaml[SDS_Repository].to_json>
    - ~webget <[Hook]> data:<[Data]> headers:<[Headers]>
